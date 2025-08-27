class ListItem < ApplicationRecord
  has_ancestry

  validates :title, presence: true

  scope :ordered, -> { order(position: :asc) }
  scope :roots, -> { where(ancestry: nil) }
  # Scope per elementi espansi/collassati
  scope :expanded, -> { where(expanded: true) }
  scope :collapsed, -> { where(expanded: false) }

  # Metodi di convenienza
  def expand!
    update!(expanded: true)
  end

  def collapse!
    update!(expanded: false)
  end

  def toggle_expanded!
    update!(expanded: !expanded?)
  end

  before_create :set_position
  after_destroy :handle_children_and_reorder

  def siblings_ordered
    siblings.order(:position, :created_at)
  end

  def children_ordered
    children.reorder(Arel.sql("COALESCE(position, 0) ASC, id ASC"))
  end

  def move_to_position(new_position, new_parent_id = nil)
    transaction do
      if new_parent_id.present?
        self.parent_id = new_parent_id
      end
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
  def deletion_preview
    {
      item_title: title,
      children_count: children.count,
      children_titles: children.pluck(:title),
      will_become_children_of: parent ? parent.title : "ROOT",
      total_descendants: descendants.count
    }
  end

  # Metodo sicuro per eliminazione che preserva children
  def destroy_preserving_children
    transaction do
      # Sposta children al parent corrente
      children.update_all(ancestry: ancestry)

      # Elimina solo questo elemento
      destroy
    end
  end

  private

  def set_position
    max_position = if parent
                     parent.children.maximum(:position) || 0
    else
                     self.class.roots.maximum(:position) || 0
    end
    self.position = max_position + 1
  end

  def handle_children_and_reorder
    transaction do
      children.update_all(ancestry: ancestry) if children.exists?
      scope = parent ? parent.children : self.class.roots
      scope.where("position > ?", position).update_all("position = position - 1")
    end
  end
end
