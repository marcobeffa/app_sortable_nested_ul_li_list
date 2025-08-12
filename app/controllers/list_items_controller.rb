# app/controllers/list_items_controller.rb
class ListItemsController < ApplicationController
  before_action :set_list_item, only: [ :show, :edit, :update, :destroy, :move ]

  def index
    @list_items = ListItem.roots.ordered
    @list_item = ListItem.new
  end

  def show
  end

  def new
    @list_item = ListItem.new
    @parent_id = params[:parent_id]

    # DEBUG: Vediamo cosa arriva
    puts "=== DEBUG NEW ACTION ==="
    puts "params[:parent_id]: #{params[:parent_id]}"
    puts "request.url: #{request.url}"
    puts "params: #{params.inspect}"
    puts "========================"

    if @parent_id.present?
      @parent_item = ListItem.find(@parent_id)
      puts "DEBUG: Parent found: #{@parent_item.title}"
    end
  end

  def create
    @list_item = ListItem.new(list_item_params)

    # IMPORTANTE: Gestisci il parent PRIMA di salvare
    if params[:list_item][:parent_id].present?
      parent = ListItem.find(params[:list_item][:parent_id])
      @list_item.parent = parent
      puts "DEBUG: Setting parent to #{parent.title} (ID: #{parent.id})"
    elsif params[:parent_id].present?
      parent = ListItem.find(params[:parent_id])
      @list_item.parent = parent
      puts "DEBUG: Setting parent to #{parent.title} (ID: #{parent.id})"
    end

    puts "DEBUG: About to save item with parent: #{@list_item.parent&.title}"

    if @list_item.save
      puts "DEBUG: Item saved successfully with parent_id: #{@list_item.parent_id}"
      redirect_to list_items_path, notice: "Item creato con successo!"
    else
      puts "DEBUG: Item save failed with errors: #{@list_item.errors.full_messages}"
      @parent_id = params[:parent_id] || params[:list_item][:parent_id]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @list_item.update(list_item_params)
      redirect_to list_items_path, notice: "Item aggiornato con successo!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @list_item.destroy
    redirect_to list_items_path, notice: "Item eliminato con successo!"
  end

  def sort
    params[:item_ids].each_with_index do |id, index|
      ListItem.find(id).update(position: index + 1)
    end

    head :ok
  end

  def move
    new_position = params[:position].to_i
    new_parent_id = params[:parent_id].presence

    # Gestisci il cambio di parent
    if new_parent_id
      new_parent = ListItem.find(new_parent_id)
      @list_item.parent = new_parent
    else
      @list_item.parent = nil
    end

    @list_item.position = new_position
    @list_item.save!

    head :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def indent
    # Sposta l'elemento sotto l'elemento precedente (aumenta indentazione)
    previous_sibling = @list_item.siblings.where("position < ?", @list_item.position).order(:position).last

    if previous_sibling
      @list_item.parent = previous_sibling
      @list_item.position = (previous_sibling.children.maximum(:position) || 0) + 1
      @list_item.save!
    end

    redirect_to list_items_path
  rescue => e
    redirect_to list_items_path, alert: "Errore durante l'indentazione: #{e.message}"
  end

  def outdent
    # Sposta l'elemento al livello del parent corrente (riduce indentazione)
    current_parent = @list_item.parent

    if current_parent
      @list_item.parent = current_parent.parent
      @list_item.position = current_parent.position + 1

      # Riordina gli elementi seguenti
      if current_parent.parent
        current_parent.parent.children.where("position > ?", current_parent.position).update_all("position = position + 1")
      else
        ListItem.roots.where("position > ?", current_parent.position).update_all("position = position + 1")
      end

      @list_item.save!
    end

    redirect_to list_items_path
  rescue => e
    redirect_to list_items_path, alert: "Errore durante l'outdentazione: #{e.message}"
  end

  private

  def set_list_item
    @list_item = ListItem.find(params[:id])
  end

  def list_item_params
    params.require(:list_item).permit(:title, :content, :parent_id)
  end
end
