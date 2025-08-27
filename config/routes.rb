
Rails.application.routes.draw do
   root "list_items#index"

    resources :list_items do
      member do
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
end
