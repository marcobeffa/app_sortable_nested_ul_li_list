
Rails.application.routes.draw do
   root "list_items#index"

    resources :list_items do
      member do
        patch :move
        patch :indent
        patch :outdent
      end
      collection do
        patch :sort
      end
    end
end
