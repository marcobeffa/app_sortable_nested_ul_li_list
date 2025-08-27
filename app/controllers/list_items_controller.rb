# app/controllers/list_items_controller.rb
class ListItemsController < ApplicationController
  before_action :set_list_item, only: [ :show, :edit, :update, :destroy, :move ]

  def index
    @list_items = ListItem.roots.ordered
    @list_item = ListItem.new
  end

  def show
  end

  def toggle_expanded
    @list_item = ListItem.find(params[:id])
    @list_item.update!(expanded: !@list_item.expanded?)

    respond_to do |format|
      format.json { render json: { expanded: @list_item.expanded? } }
    end
  end

  def new
    @list_item = ListItem.new
    @parent_id = params[:parent_id]

    # DEBUG: Vediamo cosa arriva
    # puts "=== DEBUG NEW ACTION ==="
    # puts "params[:parent_id]: #{params[:parent_id]}"
    #  puts "request.url: #{request.url}"
    # puts "params: #{params.inspect}"
    # puts "========================"

    if @parent_id.present?
      @parent_item = ListItem.find(@parent_id)
      puts "DEBUG: Parent found: #{@parent_item.title}"
    end
  end

  def create
    @list_item = ListItem.new(list_item_params)

    # Trova il parent se specificato
    parent = nil
    if params[:list_item][:parent_id].present?
      parent = ListItem.find(params[:list_item][:parent_id])
    elsif params[:parent_id].present?
      parent = ListItem.find(params[:parent_id])
    end

    # Assegna il parent al nuovo item
    @list_item.parent = parent if parent.present?

    if @list_item.save
      # DOPO il salvataggio, espandi il parent se esiste
      if parent.present? && !parent.expanded?
        parent.update(expanded: true)
      end

      redirect_to list_items_path, notice: "Item creato con successo!"
    else
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

  def destroy
    # Salva informazioni prima dell'eliminazione
    old_parent = @list_item.parent
    old_position = @list_item.position || 0
    children = @list_item.children.to_a # Converti in array per evitare problemi

    # Step 1: Riassegna ogni child al nonno, mantenendo la posizione relativa
    children.each_with_index do |child, index|
      new_position = old_position + index + 1

      if old_parent
        # Il child prende il posto del parent eliminato e i successivi si spostano
        child.update!(parent: old_parent, position: new_position)
      else
        # Diventa root con posizione calcolata
        child.update!(parent: nil, position: new_position)
      end
    end

    # Step 2: Aggiorna le posizioni dei siblings che vengono dopo
    siblings_to_update = if old_parent
      old_parent.children.where("position > ?", old_position + children.length)
    else
      ListItem.roots.where("position > ?", old_position + children.length)
    end

    siblings_to_update.each do |sibling|
      sibling.update_column(:position, sibling.position + children.length)
    end

    # Step 3: Elimina l'elemento
    @list_item.destroy!

    respond_to do |format|
      format.html { redirect_to list_items_url, notice: "Elemento eliminato. I sotto-elementi sono stati spostati al livello superiore." }
      format.json { head :no_content }
    end
  end
  # ... altri metodi esistenti ...

  private

  def set_list_item
    @list_item = ListItem.find(params[:id])
  end

  def list_item_params
    params.require(:list_item).permit(:title, :content, :parent_id, :position, :expanded)
  end

  # Metodo per riordinare le posizioni dopo eliminazione
  def reorder_positions
    # Riordina tutti gli elementi root
    ListItem.roots.order(:position, :id).each_with_index do |item, index|
      item.update_column(:position, index + 1)
    end

    # Riordina tutti i children di ogni parent
    ListItem.all.group_by(&:parent_id).each do |parent_id, siblings|
      next if parent_id.nil? # Skip roots (già fatto sopra)

      siblings.sort_by { |item| [ item.position || 0, item.id ] }.each_with_index do |item, index|
        item.update_column(:position, index + 1)
      end
    end
  end
end
