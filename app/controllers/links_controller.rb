# app/controllers/links_controller.rb
class LinksController < ApplicationController
  # GET /links/choose?item_id=123
  def choose
    @item = ListItem.find(params[:item_id])
    @search = params[:search]

    # Trova tutti gli item che possono essere linkati (escludi l'item stesso e i suoi discendenti)
    excluded_ids = [ @item.id ] + @item.descendant_ids
    @available_items = ListItem.where.not(link: true).where.not(id: excluded_ids)

    # Filtra per ricerca se presente - Case insensitive per tutti i database
    if @search.present?
      @available_items = @available_items.where("LOWER(title) LIKE ?", "%#{@search.strip.downcase}%")
    end

    @available_items = @available_items.order(:title).limit(50)
  end

  # POST /links/create
  def create
    @item = ListItem.find(params[:item_id])
    @target = ListItem.find(params[:target_id])

    @item.update!(
      link: true,
      link_item_id: @target.id
    )

    redirect_to list_items_path, notice: "Collegamento creato! #{@item.title} ora punta a #{@target.title}"
  end

  # DELETE /links/destroy/:id
  def destroy
    @item = ListItem.find(params[:id])
    @item.update!(
      link: false,
      link_item_id: nil
    )

    redirect_to list_items_path, notice: "Collegamento rimosso"
  end

 # GET /links/show/:id - Mostra l'albero del target
 def show
    @item = ListItem.find(params[:id])

    if @item.is_link?
      @target = @item.linked_item
      # CORRETTO
      @tree = @target.subtree.order(Arel.sql("COALESCE(position, 0) ASC, id ASC")).arrange
    else
      redirect_to list_items_path, alert: "Questo elemento non è un collegamento"
    end
  end
end
