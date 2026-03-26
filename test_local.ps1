# Script de test local pour Uprising Cockpit
# Lance les outils nécessaires pour tester l'application en local.

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   ⚙️ Lancement Local Uprising Cockpit 🚀    " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Vérification des prérequis
$flutterInstalled = Get-Command "flutter" -ErrorAction SilentlyContinue
if (-not $flutterInstalled) {
    Write-Host "❌ Flutter n'est pas installé ou n'est pas dans le PATH." -ForegroundColor Red
    exit 1
}

$supabaseInstalled = Get-Command "supabase" -ErrorAction SilentlyContinue
if (-not $supabaseInstalled) {
    Write-Host "⚠️ CLI Supabase non trouvée. Impossible de lancer la base de données locale si elle n'est pas déjà hébergée." -ForegroundColor Yellow
}

# 2. Se positionner dans le dossier du script
Set-Location -Path $PSScriptRoot

# 3. Optionnel: Lancement de Supabase Local
if ($supabaseInstalled) {
    Write-Host "🔄 Démarrage de Supabase Local..." -ForegroundColor Blue
    Start-Process -NoNewWindow -FilePath "supabase" -ArgumentList "start"
    Start-Sleep -Seconds 5
}

# 3. Lancement de Flutter
Write-Host "📱 Démarrage de l'application Flutter en mode test (Windows / Edge)..." -ForegroundColor Blue
# Vous pouvez changer "-d windows" selon votre émulateur préféré (chrome, edge, windows).
Start-Process -NoNewWindow -FilePath "flutter" -ArgumentList "run", "-d", "windows"

Write-Host "✅ Scripts lancés. Appuyez sur n'importe quelle touche pour quitter ce script..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
