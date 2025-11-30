#!/bin/bash

echo "🔄 Sincronizando branches..."

git checkout main
git pull origin main
echo "✅ Main atualizada"

git checkout develop  
git pull origin develop
echo "✅ Stage atualizada"

echo "🚀 Pronto para trabalhar!"
echo "✅ Todas as branches foram sincronizadas com sucesso!"
git branch -v 
