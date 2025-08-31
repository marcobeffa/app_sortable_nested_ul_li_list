
Rails.application.routes.draw do
   root "list_items#index"

    resources :list_items do
      member do
        get :export_yaml
        patch :toggle_expanded
        patch :move
        patch :indent
        patch :outdent
        post :create_link
      end
      collection do
        patch :sort
      end
    end

  # Routes per link
  get "/links/choose", to: "links#choose"
  post "/links/create", to: "links#create"
  delete "/links/:id", to: "links#destroy", as: "destroy_link"
  get "/links/:id", to: "links#show", as: "show_link"
end
