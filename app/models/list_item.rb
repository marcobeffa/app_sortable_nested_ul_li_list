class ListItem < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :finders ]
  has_ancestry

  before_create :set_position
  after_destroy :handle_children_and_reorder

  validates :title, presence: true

  scope :ordered, -> { order(position: :asc) }
  scope :roots, -> { where(ancestry: nil) }
  # Scope per elementi espansi/collassati
  scope :expanded, -> { where(expanded: true) }
  scope :collapsed, -> { where(expanded: false) }
  # Nuovi scope per link
  scope :links, -> { where(link: true) }
  scope :originals, -> { where(link: false) }

 validates :slug, uniqueness: true, allow_blank: true

  # Relazione per il link
  belongs_to :linked_item, class_name: "ListItem", foreign_key: "link_item_id", optional: true

  # Callbacks per generare slug
  before_save :generate_slug, if: -> { slug.blank? }  # Metodi semplici
  def is_link?
    link == true && link_item_id.present?
  end

  def display_title
    is_link? ? "🔗 #{title}" : title
  end

  def target_item
    is_link? ? linked_item : self
  end
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
  def should_generate_new_friendly_id?
    title_changed? || super
  end
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
  def can_have_children?
    !is_link?
  end

  def can_create_link?
    !has_children? && !is_link?
  end

  def display_title
    is_link? ? "🔗 #{title}" : title
  end
  # Metodi per styling
  def inline_style
    "color: #{text_color || '#374151'}; background-color: #{background_color || '#ffffff'};"
  end

  def to_param
    slug.present? ? slug : id.to_s
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
  def cannot_have_children_and_be_link
    if is_link? && children.any?
      errors.add(:link, "non può essere attivo se l'elemento ha figli")
    end
  end

  def cannot_have_link_with_children
    if link_item_id.present? && children.any?
      errors.add(:link_item_id, "non può essere impostato se l'elemento ha figli")
    end
  end
  # Versione migliorata del sistema attuale
  def generate_slug
    return if title.blank?

    base_slug = title.parameterize
    return if slug == base_slug # Non cambiare se è già corretto

    candidate_slug = base_slug
    counter = 1

    # Escludi questo record dalla ricerca per evitare falsi positivi negli update
    scope = ListItem.where.not(id: id || 0)

    while scope.exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end
end
