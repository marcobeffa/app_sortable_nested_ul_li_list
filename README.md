# 1. Crea la nuova app Rails 8 con TailwindCSS
rails new sortable_lists_app --css tailwind --javascript importmap
cd sortable_lists_app

# 2. Aggiungi le gems necessarie al Gemfile
echo '
# Gems per nested set e sortable
gem "ancestry"
gem "stimulus-rails"
' >> Gemfile

# 3. Installa le gems
bundle install

# 4. Genera il modello per le liste con ancestry per la gestione nested
rails generate model ListItem title:string content:text position:integer ancestry:string
rails db:migrate

# 5. Configura Stimulus per il drag & drop
rails generate stimulus sortable

# 6. Genera il controller
rails generate controller ListItems index show new create edit update destroy

# 7. Configura le routes
echo '
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
' > config/routes.rb

# 8. Aggiungi SortableJS via importmap
echo 'pin "sortablejs", to: "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js"' >> config/importmap.rb

echo "Setup completato! Ora configura i file generati come mostrato negli artifact successivi."

##  Migrazione consigliata
def change
  add_column :list_items, :position, :integer, default: 0, null: false
  add_index  :list_items, [:ancestry, :position]
end

