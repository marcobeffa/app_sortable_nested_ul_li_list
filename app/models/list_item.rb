class ListItem < ApplicationRecord
  has_ancestry
  validates :title, presence: true
  scope :ordered, -> { order(:position, :created_at) }
  scope :roots, -> { where(ancestry: nil) }

  before_create :set_position
  after_destroy :handle_children_and_reorder  # <-- CAMBIA NOME

  def siblings_ordered
    siblings.order(:position, :created_at)
  end

  def children_ordered
    children.order(:position, :created_at)
  end

  def move_to_position(new_position, new_parent_id = nil)
    transaction do
      if new_parent_id.present?
        self.parent_id = new_parent_id
      end
      # Riordina le posizioni
      if new_parent_id && parent
        siblings = parent.children
      else
        siblings = self.class.roots
      end
      siblings.where("position >= ?", new_position)
             .where.not(id: id)
             .update_all("position = position + 1")
      self.position = new_position
      save!
    end
  end

  private

  def set_position
    if parent
      max_position = parent.children.maximum(:position) || 0
    else
      max_position = self.class.roots.maximum(:position) || 0
    end
    self.position = max_position + 1
  end

  # SOSTITUISCI IL METODO PRECEDENTE CON QUESTO:
  def handle_children_and_reorder
    transaction do
      # 1. Sposta i figli al parent dell'elemento cancellato
      if children.exists?
        children.update_all(ancestry: ancestry) # ancestry contiene il path del parent
      end

      # 2. Riordina le posizioni dei siblings rimasti
      siblings_to_update = if parent
                            parent.children.where("position > ?", position)
      else
                            self.class.roots.where("position > ?", position)
      end

      siblings_to_update.update_all("position = position - 1")
    end
  end
end
