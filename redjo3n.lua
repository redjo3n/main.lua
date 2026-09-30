-- language: Lua (Luau), file: redj03n_steal_egg_v2.lua
-- RedJ03N - Steal an Egg | UPGRADED v2
-- Features from Axur Hub, Pig Hub, SoftKillz, Gemini PVP, UB Hub, ON Hub, Aj Jans Hub, CRZHub, Monarch, Decode, Moonblack
-- COPY EVERYTHING. PASTE. EXECUTE.

if _G.RedJ03N_StealEgg then
    pcall(function()
        local gui = game.CoreGui:FindFirstChild("RedJ03N_StealEgg")
        if gui then gui:Destroy() end
    end)
end
_G.RedJ03N_StealEgg = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local SG = game:GetService("StarterGui")
local WS = game:GetService("Workspace")
local LT = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local VU = nil
pcall(function() VU = game:GetService("VirtualUser") end)

local LP = Players.LocalPlayer
local DISCORD_LINK = "https://discord.gg/redj03n"

-- Theme
local C = {
    bg=Color3.fromRGB(10,8,12), panel=Color3.fromRGB(18,14,22),
    panel2=Color3.fromRGB(26,20,32), accent=Color3.fromRGB(220,30,60),
    accent2=Color3.fromRGB(255,80,120), text=Color3.fromRGB(240,235,245),
    muted=Color3.fromRGB(140,130,155), on=Color3.fromRGB(0,240,160),
    off=Color3.fromRGB(180,175,200), danger=Color3.fromRGB(255,60,90),
    gold=Color3.fromRGB(255,200,60), cyan=Color3.fromRGB(0,220,255),
}
local FB, FM, FS = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.GothamSemibold

-- Remotes
local DataPullFunc
pcall(function()
    local CL = RS:FindFirstChild("CommonLibrary")
    if CL then
        local Tool = CL:FindFirstChild("Tool")
        if Tool then
            local RM = Tool:FindFirstChild("RemoteManager")
            if RM then
                local Funcs = RM:FindFirstChild("Funcs")
                if Funcs then DataPullFunc = Funcs:FindFirstChild("DataPullFunc") end
            end
        end
    end
end)

-- State
local F = {
    -- Farm
    autoSteal=false, autoBigEgg=false, autoSecretEgg=false, autoRarestEgg=false,
    onlyHighValue=false, onlyMutations=false, stealOnce=false, fastGrab=false,
    prediction=false, antiTraps=false, autoDropHeld=false, autoReturn=false,
    autoCosmic=false, riftHunt=false, autoEventMonster=false, autoParasite=false,
    autoBoss=false, capture=false,
    -- Hatch
    autoHatch=false, autoHatchCosmic=false, autoHatchPrehistoric=false,
    -- Place
    autoPlace=false, placeHeld=false,
    -- Sell
    autoSell=false, protectFavorites=false, protectValuable=false,
    -- Treadmill
    autoTreadmill=false, autoUpgrade=false, autoBaseUpgrade=false,
    -- Claim
    autoClaim=false, collectIndex=false, collectGroup=false, collectOffline=false,
    -- Equip
    autoEquipBest=false, autoEquipTeam=false,
    -- Fuse
    autoFuse=false,
    -- Buy
    autoBuyTrails=false, autoBuyProducts=false, hookProductID=false,
    -- Visual
    espEggs=false, espPets=false, espTraps=false, fullBright=false,
    petMutation=false, addVisualPet=false, equipVisualPet=false,
    -- Movement
    speed=false, fly=false, noclip=false, antiRagdoll=false, tpWalk=false,
    -- PVP
    pvpEsp=false, aimbot=false,
    -- Misc
    webhook=false, serverHop=false, antiAfk=true,
    -- Config
    selectedArea="All", selectedRarity="All", selectedMutation="All",
    minBigEggSize=100, stealSpeed=200, flySpeed=120, tpWalkSpeed=200,
    hatchDelay=2, placeDelay=1, upgradeDelay=3, webhookURL="",
}

local CFG = { STEAL_SPEED=200, FLY_SPEED=120, TP_WALK_SPEED=200, STEAL_RANGE=500, HATCH_DELAY=2, PLACE_DELAY=1, UPGRADE_DELAY=3 }

-- Language system (from v1, keeping all 6 languages)
local LANG = "en"
local L = {}

local LANGS = {
    en = {
        title="REDJ03N", subtitle="steal an egg · v2", welcome="WELCOME",
        madeBy="Made by RedJ03N", chooseLang="Choose Your Language",
        loading="Loading...", ready="Ready!",
        farm="Farm", hatch="Hatch & Place", sell="Sell & Upgrade",
        events="Events", visual="Visual", movement="Movement",
        pvp="PVP", misc="Misc", settings="Settings",
        autoSteal="Auto Steal Egg", autoBigEgg="Auto Steal Big Egg",
        autoSecretEgg="Auto Steal Secret Egg", autoRarestEgg="Auto Steal Rarest Egg",
        onlyHighValue="Only High Value Eggs", onlyMutations="Only Mutations",
        stealOnce="Steal Egg Once", fastGrab="Fast Grab Mode",
        prediction="Prediction", antiTraps="Anti Traps",
        autoDropHeld="Auto Drop Held Egg", autoReturn="Auto Return to Base",
        autoCosmic="Auto Cosmic", riftHunt="Rift Hunt Mode",
        autoEventMonster="Auto Event Monster", autoParasite="Auto Parasite",
        autoBoss="Auto Boss", capture="Capture",
        autoHatch="Auto Hatch All", autoHatchCosmic="Auto Hatch Cosmic",
        autoHatchPrehistoric="Auto Hatch Prehistoric",
        autoPlace="Auto Place", placeHeld="Place Held Eggs",
        autoSell="Auto Sell Pets", protectFavorites="Protect Favorites",
        protectValuable="Protect Most Valuable",
        autoTreadmill="Auto Treadmill", autoUpgrade="Auto Upgrade",
        autoBaseUpgrade="Auto Base Upgrade",
        autoClaim="Auto Claim", collectIndex="Collect Index Rewards",
        collectGroup="Collect Group Rewards", collectOffline="Collect Offline Income",
        autoEquipBest="Auto Equip Best Pet", autoEquipTeam="Auto Equip Strongest Team",
        autoFuse="Auto Fuse Pets",
        autoBuyTrails="Buy Selected Trails", autoBuyProducts="Buy Products",
        hookProductID="Hook Product ID",
        espEggs="ESP Eggs", espPets="ESP Pets", espTraps="ESP Traps",
        fullBright="Full Bright", petMutation="Pet Mutation",
        addVisualPet="Add Visual Pet", equipVisualPet="Equip Visual Pet",
        speed="Speed Hack", fly="Fly (WASD)", noclip="Noclip",
        antiRagdoll="Anti Ragdoll", tpWalk="TP Walk",
        pvpEsp="PVP ESP (Red)", aimbot="Aimbot",
        webhook="Discord Webhook", serverHop="Server Hop", antiAfk="Anti-AFK",
        selectedArea="Selected Area", selectedRarity="Selected Rarity",
        selectedMutation="Selected Mutation", minBigEggSize="Min Big Egg Size",
        stealSpeed="Steal Speed", flySpeed="Fly Speed", tpWalkSpeed="TP Walk Speed",
        hatchDelay="Hatch Delay", placeDelay="Place Delay", upgradeDelay="Upgrade Delay",
        discordBtn="Discord", destroy="Destroy UI", stopAll="STOP ALL",
        active="Active", idle="Idle", eggs="Eggs", pets="Pets",
        level="Level", close="Close", minimize="Minimize",
    },
    es = {
        title="REDJ03N", subtitle="roba un huevo · v2", welcome="BIENVENIDO",
        madeBy="Hecho por RedJ03N", chooseLang="Elige tu idioma",
        loading="Cargando...", ready="Listo!",
        farm="Granja", hatch="Eclosionar", sell="Vender y Mejorar",
        events="Eventos", visual="Visual", movement="Movimiento",
        pvp="PVP", misc="Varios", settings="Ajustes",
        autoSteal="Auto Robar Huevo", autoBigEgg="Auto Robar Huevo Grande",
        autoSecretEgg="Auto Robar Huevo Secreto", autoRarestEgg="Auto Robar Más Raro",
        onlyHighValue="Solo Huevos Valiosos", onlyMutations="Solo Mutaciones",
        stealOnce="Robar Una Vez", fastGrab="Modo Rápido",
        prediction="Predicción", antiTraps="Anti Trampas",
        autoDropHeld="Soltar Huevo Sostenido", autoReturn="Regresar a Casa",
        autoCosmic="Auto Cósmico", riftHunt="Modo Rift",
        autoEventMonster="Auto Monstruo", autoParasite="Auto Parásito",
        autoBoss="Auto Jefe", capture="Capturar",
        autoHatch="Auto Eclosionar Todo", autoHatchCosmic="Auto Eclosionar Cósmico",
        autoHatchPrehistoric="Auto Eclosionar Prehistórico",
        autoPlace="Auto Colocar", placeHeld="Colocar Huevos Sostenidos",
        autoSell="Auto Vender Mascotas", protectFavorites="Proteger Favoritos",
        protectValuable="Proteger Más Valioso",
        autoTreadmill="Auto Cinta", autoUpgrade="Auto Mejorar",
        autoBaseUpgrade="Auto Mejorar Base",
        autoClaim="Auto Reclamar", collectIndex="Coleccionar Índice",
        collectGroup="Coleccionar Grupo", collectOffline="Coleccionar Ingresos",
        autoEquipBest="Auto Equipar Mejor", autoEquipTeam="Auto Equipar Equipo",
        autoFuse="Auto Fusionar",
        autoBuyTrails="Comprar Rastros", autoBuyProducts="Comprar Productos",
        hookProductID="Enganchar ID",
        espEggs="ESP Huevos", espPets="ESP Mascotas", espTraps="ESP Trampas",
        fullBright="Brillo Total", petMutation="Mutación de Mascota",
        addVisualPet="Añadir Mascota Visual", equipVisualPet="Equipar Mascota Visual",
        speed="Velocidad", fly="Volar (WASD)", noclip="Atravesar Paredes",
        antiRagdoll="Anti Ragdoll", tpWalk="Caminar TP",
        pvpEsp="ESP PVP (Rojo)", aimbot="Aimbot",
        webhook="Webhook Discord", serverHop="Cambiar Servidor", antiAfk="Anti-AFK",
        selectedArea="Área Seleccionada", selectedRarity="Rareza Seleccionada",
        selectedMutation="Mutación Seleccionada", minBigEggSize="Tamaño Mínimo",
        stealSpeed="Velocidad de Robo", flySpeed="Velocidad de Vuelo", tpWalkSpeed="Velocidad TP",
        hatchDelay="Retraso Eclosión", placeDelay="Retraso Colocación", upgradeDelay="Retraso Mejora",
        discordBtn="Discord", destroy="Destruir UI", stopAll="DETENER TODO",
        active="Activo", idle="Inactivo", eggs="Huevos", pets="Mascotas",
        level="Nivel", close="Cerrar", minimize="Minimizar",
    },
    fr = {
        title="REDJ03N", subtitle="vole un oeuf · v2", welcome="BIENVENUE",
        madeBy="Créé par RedJ03N", chooseLang="Choisissez votre langue",
        loading="Chargement...", ready="Prêt!",
        farm="Ferme", hatch="Éclore", sell="Vendre et Améliorer",
        events="Événements", visual="Visuel", movement="Mouvement",
        pvp="PVP", misc="Divers", settings="Paramètres",
        autoSteal="Auto Voler Oeuf", autoBigEgg="Auto Voler Gros Oeuf",
        autoSecretEgg="Auto Voler Oeuf Secret", autoRarestEgg="Auto Voler Plus Rare",
        onlyHighValue="Oeufs de Valeur Seulement", onlyMutations="Mutations Seulement",
        stealOnce="Voler Une Fois", fastGrab="Mode Rapide",
        prediction="Prédiction", antiTraps="Anti Pièges",
        autoDropHeld="Lâcher Oeuf Tenu", autoReturn="Retour à la Base",
        autoCosmic="Auto Cosmique", riftHunt="Mode Rift",
        autoEventMonster="Auto Monstre", autoParasite="Auto Parasite",
        autoBoss="Auto Boss", capture="Capturer",
        autoHatch="Auto Éclore Tout", autoHatchCosmic="Auto Éclore Cosmique",
        autoHatchPrehistoric="Auto Éclore Préhistorique",
        autoPlace="Auto Placer", placeHeld="Placer Oeufs Tenu",
        autoSell="Auto Vendre Animaux", protectFavorites="Protéger Favoris",
        protectValuable="Protéger Plus Valeureux",
        autoTreadmill="Auto Tapis", autoUpgrade="Auto Améliorer",
        autoBaseUpgrade="Auto Améliorer Base",
        autoClaim="Auto Réclamer", collectIndex="Collecter Index",
        collectGroup="Collecter Groupe", collectOffline="Collecter Revenus",
        autoEquipBest="Auto Équiper Meilleur", autoEquipTeam="Auto Équiper Équipe",
        autoFuse="Auto Fusionner",
        autoBuyTrails="Acheter Traînées", autoBuyProducts="Acheter Produits",
        hookProductID="Accrocher ID",
        espEggs="ESP Oeufs", espPets="ESP Animaux", espTraps="ESP Pièges",
        fullBright="Pleine Luminosité", petMutation="Mutation Animal",
        addVisualPet="Ajouter Animal Visuel", equipVisualPet="Équiper Animal Visuel",
        speed="Vitesse", fly="Voler (WASD)", noclip="Traverser Murs",
        antiRagdoll="Anti Ragdoll", tpWalk="Marche TP",
        pvpEsp="ESP PVP (Rouge)", aimbot="Aimbot",
        webhook="Webhook Discord", serverHop="Changer Serveur", antiAfk="Anti-AFK",
        selectedArea="Zone Sélectionnée", selectedRarity="Rareté Sélectionnée",
        selectedMutation="Mutation Sélectionnée", minBigEggSize="Taille Minimale",
        stealSpeed="Vitesse de Vol", flySpeed="Vitesse de Vol", tpWalkSpeed="Vitesse TP",
        hatchDelay="Délai Éclosion", placeDelay="Délai Placement", upgradeDelay="Délai Amélioration",
        discordBtn="Discord", destroy="Détruire UI", stopAll="TOUT ARRÊTER",
        active="Actif", idle="Inactif", eggs="Oeufs", pets="Animaux",
        level="Niveau", close="Fermer", minimize="Minimiser",
    },
    de = {
        title="REDJ03N", subtitle="stehle ein ei · v2", welcome="WILLKOMMEN",
        madeBy="Erstellt von RedJ03N", chooseLang="Wähle deine Sprache",
        loading="Laden...", ready="Bereit!",
        farm="Farm", hatch="Ausbrüten", sell="Verkaufen & Verbessern",
        events="Events", visual="Visuell", movement="Bewegung",
        pvp="PVP", misc="Sonstiges", settings="Einstellungen",
        autoSteal="Auto Ei Stehlen", autoBigEgg="Auto Großes Ei",
        autoSecretEgg="Auto Geheimes Ei", autoRarestEgg="Auto Seltenstes Ei",
        onlyHighValue="Nur Wertvolle Eier", onlyMutations="Nur Mutationen",
        stealOnce="Einmal Stehlen", fastGrab="Schnellmodus",
        prediction="Vorhersage", antiTraps="Anti Fallen",
        autoDropHeld="Gehaltenes Ei Fallenlassen", autoReturn="Zurück zur Basis",
        autoCosmic="Auto Kosmisch", riftHunt="Rift-Modus",
        autoEventMonster="Auto Monster", autoParasite="Auto Parasit",
        autoBoss="Auto Boss", capture="Fangen",
        autoHatch="Auto Alles Ausbrüten", autoHatchCosmic="Auto Kosmisch Ausbrüten",
        autoHatchPrehistoric="Auto Prähistorisch Ausbrüten",
        autoPlace="Auto Platzieren", placeHeld="Gehaltene Eier Platzieren",
        autoSell="Auto Haustiere Verkaufen", protectFavorites="Favoriten Schützen",
        protectValuable="Wertvollste Schützen",
        autoTreadmill="Auto Laufband", autoUpgrade="Auto Verbessern",
        autoBaseUpgrade="Auto Basis Verbessern",
        autoClaim="Auto Belohnungen", collectIndex="Index Sammeln",
        collectGroup="Gruppe Sammeln", collectOffline="Offline Einkommen",
        autoEquipBest="Auto Bestes Ausrüsten", autoEquipTeam="Auto Team Ausrüsten",
        autoFuse="Auto Fusionieren",
        autoBuyTrails="Spuren Kaufen", autoBuyProducts="Produkte Kaufen",
        hookProductID="Produkt ID Haken",
        espEggs="ESP Eier", espPets="ESP Haustiere", espTraps="ESP Fallen",
        fullBright="Volle Helligkeit", petMutation="Haustier Mutation",
        addVisualPet="Visuelles Haustier", equipVisualPet="Visuelles Ausrüsten",
        speed="Geschwindigkeit", fly="Fliegen (WASD)", noclip="Durch Wände",
        antiRagdoll="Anti Ragdoll", tpWalk="TP Gehen",
        pvpEsp="PVP ESP (Rot)", aimbot="Aimbot",
        webhook="Discord Webhook", serverHop="Server Wechseln", antiAfk="Anti-AFK",
        selectedArea="Ausgewählter Bereich", selectedRarity="Ausgewählte Seltenheit",
        selectedMutation="Ausgewählte Mutation", minBigEggSize="Min Größe",
        stealSpeed="Stehlgeschwindigkeit", flySpeed="Fluggeschwindigkeit", tpWalkSpeed="TP Geschwindigkeit",
        hatchDelay="Brutverzögerung", placeDelay="Platzierungsverzögerung", upgradeDelay="Verbesserungsverzögerung",
        discordBtn="Discord", destroy="UI Zerstören", stopAll="ALLES STOPPEN",
        active="Aktiv", idle="Inaktiv", eggs="Eier", pets="Haustiere",
        level="Level", close="Schließen", minimize="Minimieren",
    },
    pt = {
        title="REDJ03N", subtitle="roube um ovo · v2", welcome="BEM-VINDO",
        madeBy="Feito por RedJ03N", chooseLang="Escolha seu idioma",
        loading="Carregando...", ready="Pronto!",
        farm="Fazenda", hatch="Chocar", sell="Vender & Melhorar",
        events="Eventos", visual="Visual", movement="Movimento",
        pvp="PVP", misc="Diversos", settings="Configurações",
        autoSteal="Auto Roubar Ovo", autoBigEgg="Auto Roubar Ovo Grande",
        autoSecretEgg="Auto Roubar Ovo Secreto", autoRarestEgg="Auto Roubar Mais Raro",
        onlyHighValue="Apenas Ovos Valiosos", onlyMutations="Apenas Mutações",
        stealOnce="Roubar Uma Vez", fastGrab="Modo Rápido",
        prediction="Previsão", antiTraps="Anti Armadilhas",
        autoDropHeld="Soltar Ovo Seguro", autoReturn="Voltar à Base",
        autoCosmic="Auto Cósmico", riftHunt="Modo Rift",
        autoEventMonster="Auto Monstro", autoParasite="Auto Parasita",
        autoBoss="Auto Chefe", capture="Capturar",
        autoHatch="Auto Chocar Tudo", autoHatchCosmic="Auto Chocar Cósmico",
        autoHatchPrehistoric="Auto Chocar Pré-histórico",
        autoPlace="Auto Colocar", placeHeld="Colocar Ovos Seguros",
        autoSell="Auto Vender Pets", protectFavorites="Proteger Favoritos",
        protectValuable="Proteger Mais Valioso",
        autoTreadmill="Auto Esteira", autoUpgrade="Auto Melhorar",
        autoBaseUpgrade="Auto Melhorar Base",
        autoClaim="Auto Resgatar", collectIndex="Coletar Índice",
        collectGroup="Coletar Grupo", collectOffline="Coletar Renda",
        autoEquipBest="Auto Equipar Melhor", autoEquipTeam="Auto Equipar Time",
        autoFuse="Auto Fusionar",
        autoBuyTrails="Comprar Rastros", autoBuyProducts="Comprar Produtos",
        hookProductID="Enganchar ID",
        espEggs="ESP Ovos", espPets="ESP Pets", espTraps="ESP Armadilhas",
        fullBright="Brilho Total", petMutation="Mutação de Pet",
        addVisualPet="Adicionar Pet Visual", equipVisualPet="Equipar Pet Visual",
        speed="Velocidade", fly="Voar (WASD)", noclip="Atravessar Paredes",
        antiRagdoll="Anti Ragdoll", tpWalk="Caminhar TP",
        pvpEsp="ESP PVP (Vermelho)", aimbot="Aimbot",
        webhook="Webhook Discord", serverHop="Trocar Servidor", antiAfk="Anti-AFK",
        selectedArea="Área Selecionada", selectedRarity="Raridade Selecionada",
        selectedMutation="Mutação Selecionada", minBigEggSize="Tamanho Mínimo",
        stealSpeed="Velocidade de Roubo", flySpeed="Velocidade de Voo", tpWalkSpeed="Velocidade TP",
        hatchDelay="Atraso Choco", placeDelay="Atraso Colocação", upgradeDelay="Atraso Melhoria",
        discordBtn="Discord", destroy="Destruir UI", stopAll="PARAR TUDO",
        active="Ativo", idle="Inativo", eggs="Ovos", pets="Pets",
        level="Nível", close="Fechar", minimize="Minimizar",
    },
    ar = {
        title="REDJ03N", subtitle="سرقة بيضة · v2", welcome="مرحبا",
        madeBy="صنع بواسطة RedJ03N", chooseLang="اختر لغتك",
        loading="جاري التحميل...", ready="جاهز!",
        farm="مزرعة", hatch="تفقيس", sell="بيع و ترقية",
        events="أحداث", visual="مرئي", movement="حركة",
        pvp="قتال", misc="متنوع", settings="الإعدادات",
        autoSteal="سرقة بيضة تلقائي", autoBigEgg="سرقة بيضة كبيرة",
        autoSecretEgg="سرقة بيضة سرية", autoRarestEgg="سرقة أندر بيضة",
        onlyHighValue="فقط البيض الثمين", onlyMutations="فقط الطفرات",
        stealOnce="سرقة مرة واحدة", fastGrab="وضع سريع",
        prediction="توقع", antiTraps="مضاد الفخاخ",
        autoDropHeld="إسقاط البيضة المحمولة", autoReturn="العودة للقاعدة",
        autoCosmic="تلقائي كوني", riftHunt="وضع الشق",
        autoEventMonster="تلقائي وحش", autoParasite="تلقائي طفيلي",
        autoBoss="تلقائي زعيم", capture="أسر",
        autoHatch="تفقيس الكل تلقائي", autoHatchCosmic="تفقيس كوني",
        autoHatchPrehistoric="تفقيس ما قبل التاريخ",
        autoPlace="وضع تلقائي", placeHeld="وضع البيض المحمول",
        autoSell="بيع الحيوانات تلقائي", protectFavorites="حماية المفضلة",
        protectValuable="حماية الأكثر قيمة",
        autoTreadmill="سير تلقائي", autoUpgrade="ترقية تلقائية",
        autoBaseUpgrade="ترقية القاعدة",
        autoClaim="استلام المكافآت", collectIndex="جمع الفهرس",
        collectGroup="جمع المجموعة", collectOffline="جمع الدخل",
        autoEquipBest="تجهيز الأفضل", autoEquipTeam="تجهيز الفريق",
        autoFuse="دمج تلقائي",
        autoBuyTrails="شراء المسارات", autoBuyProducts="شراء المنتجات",
        hookProductID="ربط معرف المنتج",
        espEggs="رؤية البيض", espPets="رؤية الحيوانات", espTraps="رؤية الفخاخ",
        fullBright="سطوع كامل", petMutation="طفرة الحيوان",
        addVisualPet="إضافة حيوان مرئي", equipVisualPet="تجهيز حيوان مرئي",
        speed="سرعة", fly="طيران (WASD)", noclip="اختراق الجدران",
        antiRagdoll="مضاد السقوط", tpWalk="مشي TP",
        pvpEsp="رؤية PVP (أحمر)", aimbot="تصويب تلقائي",
        webhook="ويب هوك ديسكورد", serverHop="تغيير السيرفر", antiAfk="مضاد الخمول",
        selectedArea="المنطقة المختارة", selectedRarity="الندرة المختارة",
        selectedMutation="الطفرة المختارة", minBigEggSize="الحد الأدنى للحجم",
        stealSpeed="سرعة السرقة", flySpeed="سرعة الطيران", tpWalkSpeed="سرعة TP",
        hatchDelay="تأخير التفقيس", placeDelay="تأخير الوضع", upgradeDelay="تأخير الترقية",
        discordBtn="ديسكورد", destroy="تدمير الواجهة", stopAll="إيقاف الكل",
        active="نشط", idle="خامل", eggs="بيض", pets="حيوانات",
        level="مستوى", close="إغلاق", minimize="تصغير",
    },
}

-- ============================================================
-- LOADING POPUP + LANGUAGE SELECTION
-- ============================================================
local function showLoadingPopup()
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "RedJ03N_Loading"
    popupGui.Parent = game.CoreGui
    popupGui.ResetOnSpawn = false
    popupGui.DisplayOrder = 1000

    local overlay = Instance.new("Frame", popupGui)
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0

    local popup = Instance.new("Frame", popupGui)
    popup.Size = UDim2.new(0,440,0,420)
    popup.Position = UDim2.new(0.5,-220,0.5,-210)
    popup.BackgroundColor3 = C.bg
    popup.BorderSizePixel = 0
    popup.ClipsDescendants = true
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0,16)

    local ps = Instance.new("UIStroke", popup)
    ps.Color = C.accent; ps.Thickness = 2; ps.Transparency = 0.1

    local ab = Instance.new("Frame", popup)
    ab.Size = UDim2.new(1,0,0,4); ab.BackgroundColor3 = C.accent; ab.BorderSizePixel = 0
    Instance.new("UICorner", ab).CornerRadius = UDim.new(0,16)

    local title = Instance.new("TextLabel", popup)
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0,20,0,16)
    title.Size = UDim2.new(1,-40,0,32)
    title.Font = FB; title.Text = "REDJ03N"; title.TextColor3 = C.accent
    title.TextSize = 30; title.TextXAlignment = Enum.TextXAlignment.Center

    local sub = Instance.new("TextLabel", popup)
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.new(0,20,0,50)
    sub.Size = UDim2.new(1,-40,0,18)
    sub.Font = FM; sub.Text = "steal an egg · v2"; sub.TextColor3 = C.muted
    sub.TextSize = 11; sub.TextXAlignment = Enum.TextXAlignment.Center

    local welcome = Instance.new("TextLabel", popup)
    welcome.BackgroundTransparency = 1
    welcome.Position = UDim2.new(0,20,0,78)
    welcome.Size = UDim2.new(1,-40,0,26)
    welcome.Font = FB; welcome.Text = "WELCOME"; welcome.TextColor3 = C.text
    welcome.TextSize = 20; welcome.TextXAlignment = Enum.TextXAlignment.Center

    local madeBy = Instance.new("TextLabel", popup)
    madeBy.BackgroundTransparency = 1
    madeBy.Position = UDim2.new(0,20,0,104)
    madeBy.Size = UDim2.new(1,-40,0,16)
    madeBy.Font = FM; madeBy.Text = "Made by RedJ03N"; madeBy.TextColor3 = C.gold
    madeBy.TextSize = 11; madeBy.TextXAlignment = Enum.TextXAlignment.Center

    local chooseText = Instance.new("TextLabel", popup)
    chooseText.BackgroundTransparency = 1
    chooseText.Position = UDim2.new(0,20,0,130)
    chooseText.Size = UDim2.new(1,-40,0,22)
    chooseText.Font = FB; chooseText.Text = "Choose Your Language"
    chooseText.TextColor3 = C.accent2; chooseText.TextSize = 14
    chooseText.TextXAlignment = Enum.TextXAlignment.Center

    local langFrame = Instance.new("Frame", popup)
    langFrame.BackgroundTransparency = 1
    langFrame.Position = UDim2.new(0,20,0,160)
    langFrame.Size = UDim2.new(1,-40,0,200)
    local ll = Instance.new("UIListLayout", langFrame)
    ll.Padding = UDim.new(0,6); ll.SortOrder = Enum.SortOrder.LayoutOrder

    local languages = {
        {code="en", name="English", flag="🇬🇧"},
        {code="es", name="Español", flag="🇪🇸"},
        {code="fr", name="Français", flag="🇫🇷"},
        {code="de", name="Deutsch", flag="🇩🇪"},
        {code="pt", name="Português", flag="🇵🇹"},
        {code="ar", name="العربية", flag="🇸🇦"},
    }

    for _, lang in ipairs(languages) do
        local btn = Instance.new("TextButton", langFrame)
        btn.Size = UDim2.new(1,0,0,36)
        btn.BackgroundColor3 = C.panel
        btn.Font = FS; btn.Text = lang.flag .. "  " .. lang.name
        btn.TextColor3 = C.text; btn.TextSize = 13
        btn.AutoButtonColor = false; btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
        local s = Instance.new("UIStroke", btn); s.Color = C.accent; s.Transparency = 0.7
        btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.panel2}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.panel}):Play() end)
        btn.MouseButton1Click:Connect(function()
            LANG = lang.code
            L = LANGS[LANG]
            welcome.Text = L.welcome; madeBy.Text = L.madeBy; chooseText.Text = L.ready
            TweenService:Create(popup,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
            TweenService:Create(ps,TweenInfo.new(0.3),{Transparency=1}):Play()
            for _, ch in ipairs(popup:GetDescendants()) do
                if ch:IsA("TextLabel") or ch:IsA("TextButton") then
                    TweenService:Create(ch,TweenInfo.new(0.3),{TextTransparency=1}):Play()
                end
            end
            task.wait(0.35)
            popupGui:Destroy()
            _G.OpenMainGUI()
        end)
    end

    local discordBtn = Instance.new("TextButton", popup)
    discordBtn.Position = UDim2.new(0,20,1,-56)
    discordBtn.Size = UDim2.new(1,-40,0,34)
    discordBtn.BackgroundColor3 = C.panel2
    discordBtn.Font = FS; discordBtn.Text = "💬  Join our Discord"
    discordBtn.TextColor3 = C.cyan; discordBtn.TextSize = 12
    discordBtn.AutoButtonColor = false; discordBtn.BorderSizePixel = 0
    Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0,8)
    discordBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(DISCORD_LINK) end)
        pcall(function()
            SG:SetCore("SendNotification",{Title="RedJ03N",Text="Discord link copied!",Duration=5})
        end)
    end)
end

-- ============================================================
-- MAIN GUI
-- ============================================================
_G.OpenMainGUI = function()
    local parentGui = game.CoreGui
    pcall(function() if gethui then parentGui = gethui() end end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "RedJ03N_StealEgg"
    gui.Parent = parentGui
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999

    local Main = Instance.new("Frame", gui)
    Main.Size = UDim2.new(0,660,0,470)
    Main.Position = UDim2.new(0.5,-330,0.5,-235)
    Main.BackgroundColor3 = C.bg
    Main.BorderSizePixel = 0
    Main.Active = true; Main.Draggable = true; Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)

    local ms = Instance.new("UIStroke", Main); ms.Color = C.accent; ms.Thickness = 2; ms.Transparency = 0.1

    local Head = Instance.new("Frame", Main)
    Head.Size = UDim2.new(1,0,0,56); Head.BackgroundColor3 = C.panel; Head.BorderSizePixel = 0
    Instance.new("UICorner", Head).CornerRadius = UDim.new(0,14)
    local HF = Instance.new("Frame", Head); HF.Position = UDim2.new(0,0,1,-14); HF.Size = UDim2.new(1,0,0,14); HF.BackgroundColor3 = C.panel; HF.BorderSizePixel = 0
    local HG = Instance.new("UIGradient", Head)
    HG.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,C.accent),ColorSequenceKeypoint.new(0.5,C.accent2),ColorSequenceKeypoint.new(1,C.accent)}
    HG.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0.82),NumberSequenceKeypoint.new(0.5,0.68),NumberSequenceKeypoint.new(1,0.82)}

    local AccBar = Instance.new("Frame", Main); AccBar.Size = UDim2.new(1,-32,0,3); AccBar.Position = UDim2.new(0,16,0,0); AccBar.BackgroundColor3 = C.accent; AccBar.BorderSizePixel = 0
    Instance.new("UICorner", AccBar).CornerRadius = UDim.new(1,0)

    local Title = Instance.new("TextLabel", Head); Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0,20,0,8); Title.Size = UDim2.new(1,-120,0,22); Title.Font = FB; Title.Text = "REDJ03N"; Title.TextColor3 = C.text; Title.TextSize = 22; Title.TextXAlignment = Enum.TextXAlignment.Left

    local Sub = Instance.new("TextLabel", Head); Sub.BackgroundTransparency = 1; Sub.Position = UDim2.new(0,20,0,30); Sub.Size = UDim2.new(1,-120,0,14); Sub.Font = FM; Sub.Text = "steal an egg · v2 · " .. LANG:upper(); Sub.TextColor3 = C.muted; Sub.TextSize = 10; Sub.TextXAlignment = Enum.TextXAlignment.Left

    local Dot = Instance.new("Frame", Head); Dot.Position = UDim2.new(1,-80,0,23); Dot.Size = UDim2.new(0,10,0,10); Dot.BackgroundColor3 = C.on; Dot.BorderSizePixel = 0
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)

    local DiscordBtn = Instance.new("TextButton", Head); DiscordBtn.Position = UDim2.new(1,-108,0,16); DiscordBtn.Size = UDim2.new(0,22,0,22); DiscordBtn.BackgroundColor3 = C.panel2; DiscordBtn.Font = FB; DiscordBtn.Text = "💬"; DiscordBtn.TextColor3 = C.cyan; DiscordBtn.TextSize = 11; DiscordBtn.AutoButtonColor = false; DiscordBtn.BorderSizePixel = 0
    Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0,6)
    DiscordBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(DISCORD_LINK) end)
        pcall(function() SG:SetCore("SendNotification",{Title="RedJ03N",Text="Discord link copied!",Duration=3}) end)
    end)

    local MinBtn = Instance.new("TextButton", Head); MinBtn.Position = UDim2.new(1,-60,0,16); MinBtn.Size = UDim2.new(0,26,0,24); MinBtn.BackgroundColor3 = C.panel2; MinBtn.Font = FB; MinBtn.Text = "—"; MinBtn.TextColor3 = C.text; MinBtn.TextSize = 14; MinBtn.AutoButtonColor = false; MinBtn.BorderSizePixel = 0
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,6)

    local CloseBtn = Instance.new("TextButton", Head); CloseBtn.Position = UDim2.new(1,-30,0,16); CloseBtn.Size = UDim2.new(0,26,0,24); CloseBtn.BackgroundColor3 = C.panel2; CloseBtn.Font = FB; CloseBtn.Text = "×"; CloseBtn.TextColor3 = C.danger; CloseBtn.TextSize = 16; CloseBtn.AutoButtonColor = false; CloseBtn.BorderSizePixel = 0
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)

    local Stat = Instance.new("TextLabel", Main); Stat.BackgroundColor3 = C.panel; Stat.Position = UDim2.new(0,0,0,56); Stat.Size = UDim2.new(1,0,0,24); Stat.Font = Enum.Font.Code; Stat.Text = "  " .. L.loading; Stat.TextColor3 = C.muted; Stat.TextSize = 10; Stat.TextXAlignment = Enum.TextXAlignment.Left; Stat.BorderSizePixel = 0

    local Side = Instance.new("Frame", Main); Side.BackgroundColor3 = C.bg; Side.Position = UDim2.new(0,0,0,80); Side.Size = UDim2.new(0,170,1,-80); Side.BorderSizePixel = 0
    local Content = Instance.new("Frame", Main); Content.BackgroundColor3 = C.panel; Content.Position = UDim2.new(0,170,0,80); Content.Size = UDim2.new(1,-170,1,-80); Content.BorderSizePixel = 0

    local Tabs = {}

    local function newTab(name, icon)
        local page = Instance.new("ScrollingFrame", Content)
        page.Size = UDim2.new(1,-12,1,-12); page.Position = UDim2.new(0,6,0,6)
        page.BackgroundTransparency = 1; page.Visible = false; page.CanvasSize = UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = C.accent; page.BorderSizePixel = 0
        local lay = Instance.new("UIListLayout", page); lay.Padding = UDim.new(0,5); lay.SortOrder = Enum.SortOrder.LayoutOrder

        local btn = Instance.new("TextButton", Side)
        btn.Size = UDim2.new(1,-12,0,36); btn.Position = UDim2.new(0,6,0,#Tabs*42+8)
        btn.BackgroundColor3 = C.bg; btn.Font = FS; btn.Text = "  " .. icon .. "  " .. name
        btn.TextColor3 = C.muted; btn.TextSize = 12; btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false; btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

        btn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Page.Visible = false; t.Btn.BackgroundColor3 = C.bg; t.Btn.TextColor3 = C.muted
            end
            page.Visible = true; btn.BackgroundColor3 = C.panel2; btn.TextColor3 = C.accent2
        end)
        Tabs[name] = { Page = page, Btn = btn }
        return page
    end

    local function section(page, txt)
        local l = Instance.new("TextLabel", page); l.BackgroundTransparency = 1; l.Size = UDim2.new(1,0,0,22); l.Font = FB; l.Text = txt:upper(); l.TextColor3 = C.accent2; l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function toggle(page, txt, key, cb)
        local b = Instance.new("TextButton", page)
        b.Size = UDim2.new(1,0,0,34); b.BackgroundColor3 = C.bg; b.Font = FM; b.Text = "  " .. txt
        b.TextColor3 = C.off; b.TextSize = 11; b.TextXAlignment = Enum.TextXAlignment.Left
        b.AutoButtonColor = false; b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        local s = Instance.new("UIStroke", b); s.Color = C.accent; s.Transparency = 0.75
        local ind = Instance.new("Frame", b); ind.Position = UDim2.new(1,-46,0.5,-8); ind.Size = UDim2.new(0,34,0,16); ind.BackgroundColor3 = C.panel2; ind.BorderSizePixel = 0
        Instance.new("UICorner", ind).CornerRadius = UDim.new(1,0)
        local knob = Instance.new("Frame", ind); knob.Position = UDim2.new(0,2,0.5,-6); knob.Size = UDim2.new(0,12,0,12); knob.BackgroundColor3 = C.off; knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local function refresh()
            if F[key] then
                ind.BackgroundColor3 = C.on; knob.Position = UDim2.new(1,-14,0.5,-6); knob.BackgroundColor3 = C.bg; b.TextColor3 = C.text
            else
                ind.BackgroundColor3 = C.panel2; knob.Position = UDim2.new(0,2,0.5,-6); knob.BackgroundColor3 = C.off; b.TextColor3 = C.off
            end
        end
        refresh()
        b.MouseButton1Click:Connect(function()
            F[key] = not F[key]; refresh()
            if cb then pcall(cb, F[key]) end
        end)
    end

    local function button(page, txt, cb)
        local b = Instance.new("TextButton", page)
        b.Size = UDim2.new(1,0,0,34); b.BackgroundColor3 = C.bg; b.Font = FM; b.Text = "  " .. txt
        b.TextColor3 = C.text; b.TextSize = 11; b.TextXAlignment = Enum.TextXAlignment.Left
        b.AutoButtonColor = false; b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        local s = Instance.new("UIStroke", b); s.Color = C.accent; s.Transparency = 0.75
        b.MouseEnter:Connect(function() b.BackgroundColor3 = C.panel2 end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = C.bg end)
        b.MouseButton1Click:Connect(function() pcall(cb) end)
    end

    local function slider(page, label, mn, mx, dflt, cb)
        local h = Instance.new("Frame", page); h.BackgroundColor3 = C.bg; h.Size = UDim2.new(1,0,0,50); h.BorderSizePixel = 0
        Instance.new("UICorner", h).CornerRadius = UDim.new(0,8)
        local hs = Instance.new("UIStroke", h); hs.Color = C.accent; hs.Transparency = 0.75
        local lbl = Instance.new("TextLabel", h); lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0,12,0,4); lbl.Size = UDim2.new(1,-24,0,16); lbl.Font = FM; lbl.Text = label .. ": " .. tostring(dflt); lbl.TextColor3 = C.text; lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local bar = Instance.new("Frame", h); bar.BackgroundColor3 = C.panel2; bar.Position = UDim2.new(0,12,0,30); bar.Size = UDim2.new(1,-24,0,6); bar.BorderSizePixel = 0
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)
        local fill = Instance.new("Frame", bar); fill.BackgroundColor3 = C.accent; fill.Size = UDim2.new((dflt-mn)/(mx-mn),0,1,0); fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
        local drag = false
        local function upd(i)
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = math.floor(mn + (mx-mn)*rel + 0.5)
            fill.Size = UDim2.new(rel,0,1,0); lbl.Text = label .. ": " .. tostring(v); cb(v)
        end
        bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true upd(i) end end)
        UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
    end

    local function dropdown(page, label, options, cb)
        local holder = Instance.new("Frame", page); holder.BackgroundColor3 = C.bg; holder.Size = UDim2.new(1,0,0,34); holder.BorderSizePixel = 0; holder.ClipsDescendants = true
        Instance.new("UICorner", holder).CornerRadius = UDim.new(0,8)
        local hs = Instance.new("UIStroke", holder); hs.Color = C.accent; hs.Transparency = 0.75
        local btn = Instance.new("TextButton", holder); btn.BackgroundTransparency = 1; btn.Size = UDim2.new(1,0,0,34); btn.Font = FM; btn.Text = "  " .. label .. ": " .. options[1]; btn.TextColor3 = C.text; btn.TextSize = 11; btn.TextXAlignment = Enum.TextXAlignment.Left
        local list = Instance.new("Frame", holder); list.BackgroundTransparency = 1; list.Position = UDim2.new(0,0,0,34); list.Size = UDim2.new(1,0,0,0); list.ClipsDescendants = true
        local ll = Instance.new("UIListLayout", list); ll.Padding = UDim.new(0,2)
        for i, opt in ipairs(options) do
            local ob = Instance.new("TextButton", list); ob.BackgroundColor3 = C.bg; ob.Size = UDim2.new(1,0,0,26); ob.Font = FM; ob.Text = opt; ob.TextColor3 = C.muted; ob.TextSize = 11; ob.AutoButtonColor = false; ob.LayoutOrder = i
            ob.MouseButton1Click:Connect(function()
                btn.Text = "  " .. label .. ": " .. opt
                holder.Size = UDim2.new(1,0,0,34); list.Size = UDim2.new(1,0,0,0); cb(opt)
            end)
        end
        local open = false
        btn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                local h = 34 + (#options*28) + 6
                TweenService:Create(holder,TweenInfo.new(0.18),{Size=UDim2.new(1,0,0,h)}):Play()
                TweenService:Create(list,TweenInfo.new(0.18),{Size=UDim2.new(1,0,0,h-34)}):Play()
            else
                TweenService:Create(holder,TweenInfo.new(0.18),{Size=UDim2.new(1,0,0,34)}):Play()
                TweenService:Create(list,TweenInfo.new(0.18),{Size=UDim2.new(1,0,0,0)}):Play()
            end
        end)
    end

    -- Tabs
    local FarmT = newTab(L.farm, "🥚")
    local HatchT = newTab(L.hatch, "🐣")
    local SellT = newTab(L.sell, "💰")
    local EventsT = newTab(L.events, "⚡")
    local VisualT = newTab(L.visual, "👁")
    local MoveT = newTab(L.movement, "🌀")
    local PvpT = newTab(L.pvp, "⚔")
    local MiscT = newTab(L.misc, "🛠")

    Tabs[L.farm].Page.Visible = true
    Tabs[L.farm].Btn.BackgroundColor3 = C.panel2
    Tabs[L.farm].Btn.TextColor3 = C.accent2

    -- Helpers
    local function char()
        local c = LP.Character
        if not c then return nil,nil,nil end
        return c, c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
    end

    local function scanEggs()
        local list = {}
        local cm = LP.Character
        for _, v in ipairs(WS:GetChildren()) do
            if v:IsA("Model") and v ~= cm then
                local n = v.Name:lower()
                if n:find("egg") or n:find("pet") or n:find("animal") then
                    local r = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                    if r then table.insert(list, v) end
                end
            end
        end
        return list
    end

    local function scanPets()
        local list = {}
        for _, v in ipairs(WS:GetChildren()) do
            if v:IsA("Model") then
                local n = v.Name:lower()
                if n:find("pet") or n:find("animal") then
                    local r = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                    if r then table.insert(list, v) end
                end
            end
        end
        return list
    end

    local function lvl()
        local ok, v = pcall(function() return LP.Data.Level.Value end)
        return ok and v or 1
    end

    -- Movement
    local moveTo = nil; local lastP = nil; local stuck = 0

    RunService.RenderStepped:Connect(function()
        if F.autoSteal or F.autoReturn or F.autoCosmic or F.riftHunt or F.autoEventMonster or F.autoBoss then
            local _, hrp = char()
            if hrp and hrp.Position.Y < 5 then
                hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0,30,0))
                hrp.Velocity = Vector3.new(0,50,0)
            end
        end
        if not (F.autoSteal or F.autoReturn or F.autoCosmic or F.riftHunt or F.autoEventMonster or F.autoBoss) then
            moveTo = nil; lastP = nil; stuck = 0; return
        end
        if not moveTo then return end
        local _, hrp = char()
        if not hrp then moveTo = nil return end
        local cur = hrp.Position
        if lastP then if (cur - lastP).Magnitude < 1 then stuck = stuck + 1 else stuck = 0 end end
        lastP = cur
        local dir = moveTo - cur; local d = dir.Magnitude
        if d < 4 then moveTo = nil return end
        if stuck >= 3 then hrp.CFrame = CFrame.new(cur + Vector3.new(0,15,0)); stuck = 0; return end
        local step = math.min(CFG.STEAL_SPEED/60, d)
        hrp.CFrame = CFrame.new(cur + dir.Unit * step)
    end)

    RunService.Heartbeat:Connect(function()
        if F.noclip or F.autoSteal or F.autoReturn or F.autoCosmic or F.riftHunt then
            pcall(function()
                local c = LP.Character; if not c then return end
                for _, v in pairs(c:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                end
            end)
        end
    end)

    -- Auto Steal Loop
    task.spawn(function()
        while task.wait(0.1) do
            if not F.autoSteal then continue end
            pcall(function()
                local c, hrp, hum = char()
                if not hrp or not hum or hum.Health <= 0 then return end
                local eggs = scanEggs()
                if #eggs == 0 then return end
                local target = eggs[1]
                if F.onlyHighValue then
                    for _, e in ipairs(eggs) do
                        local n = e.Name:lower()
                        if n:find("gold") or n:find("rainbow") or n:find("dragon") or n:find("secret") then target = e; break end
                    end
                end
                if F.onlyMutations then
                    for _, e in ipairs(eggs) do
                        local n = e.Name:lower()
                        if n:find("mutation") or n:find("mutated") then target = e; break end
                    end
                end
                if F.autoSecretEgg then
                    for _, e in ipairs(eggs) do
                        if e.Name:lower():find("secret") then target = e; break end
                    end
                end
                if F.autoRarestEgg then
                    for _, e in ipairs(eggs) do
                        local n = e.Name:lower()
                        if n:find("mythical") or n:find("divine") or n:find("legendary") then target = e; break end
                    end
                end
                if F.autoBigEgg then
                    for _, e in ipairs(eggs) do
                        local n = e.Name:lower()
                        if n:find("big") or n:find("large") or n:find("giant") then target = e; break end
                    end
                end
                local r = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
                if not r then return end
                local d = (hrp.Position - r.Position).Magnitude
                if d > 10 then
                    moveTo = r.Position + Vector3.new(0,5,0)
                else
                    moveTo = nil
                    local tool = c:FindFirstChildOfClass("Tool")
                    if tool then pcall(function() tool:Activate() end) end
                    if DataPullFunc then
                        pcall(function() DataPullFunc:InvokeServer("StealEgg", target.Name) end)
                    end
                    if F.stealOnce then F.autoSteal = false end
                end
            end)
        end
    end)

    -- Auto Cosmic
    task.spawn(function()
        while task.wait(0.5) do
            if not F.autoCosmic then continue end
            pcall(function()
                if DataPullFunc then
                    DataPullFunc:InvokeServer("AutoCosmic")
                end
            end)
        end
    end)

    -- Rift Hunt
    task.spawn(function()
        while task.wait(1) do
            if not F.riftHunt then continue end
            pcall(function()
                local _, hrp = char()
                if not hrp then return end
                for _, v in ipairs(WS:GetChildren()) do
                    if v:IsA("Model") and v.Name:lower():find("rift") then
                        local r = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                        if r then moveTo = r.Position + Vector3.new(0,5,0); break end
                    end
                end
            end)
        end
    end)

    -- Auto Event Monster
    task.spawn(function()
        while task.wait(0.5) do
            if not F.autoEventMonster then continue end
            pcall(function()
                local c, hrp = char()
                if not hrp then return end
                for _, v in ipairs(WS:GetChildren()) do
                    if v:IsA("Model") then
                        local n = v.Name:lower()
                        if n:find("monster") or n:find("parasite") or n:find("event") then
                            local r = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                            if r then
                                local d = (hrp.Position - r.Position).Magnitude
                                if d > 10 then moveTo = r.Position + Vector3.new(0,5,0)
                                else moveTo = nil
                                    local tool = c:FindFirstChildOfClass("Tool")
                                    if tool then tool:Activate() end
                                end
                                break
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- Auto Boss
    task.spawn(function()
        while task.wait(0.5) do
            if not F.autoBoss then continue end
            pcall(function()
                local c, hrp = char()
                if not hrp then return end
                for _, v in ipairs(WS:GetChildren()) do
                    if v:IsA("Model") then
                        local n = v.Name:lower()
                        if n:find("boss") or n:find("overlord") then
                            local r = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                            if r then
                                local d = (hrp.Position - r.Position).Magnitude
                                if d > 10 then moveTo = r.Position + Vector3.new(0,5,0)
                                else moveTo = nil
                                    local tool = c:FindFirstChildOfClass("Tool")
                                    if tool then tool:Activate() end
                                end
                                break
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- Auto Hatch
    task.spawn(function()
        while task.wait(CFG.HATCH_DELAY) do
            if not F.autoHatch then continue end
            pcall(function()
                if not DataPullFunc then return end
                for ch = 1, 5 do
                    pcall(function() DataPullFunc:InvokeServer("EggHatchStartChannel", ch, 24) end)
                end
                task.wait(CFG.HATCH_DELAY)
                for ch = 1, 5 do
                    pcall(function() DataPullFunc:InvokeServer("EggHatchTakenChannel", ch) end)
                end
            end)
        end
    end)

    -- Auto Place
    task.spawn(function()
        while task.wait(CFG.PLACE_DELAY) do
            if not F.autoPlace then continue end
            pcall(function()
                if DataPullFunc then DataPullFunc:InvokeServer("PlaceEgg", "Auto") end
            end)
        end
    end)

    -- Auto Sell
    task.spawn(function()
        while task.wait(2) do
            if not F.autoSell then continue end
            pcall(function()
                if DataPullFunc then DataPullFunc:InvokeServer("SellPets") end
            end)
        end
    end)

    -- Auto Treadmill
    task.spawn(function()
        while task.wait(CFG.UPGRADE_DELAY) do
            if not F.autoTreadmill then continue end
            pcall(function()
                if DataPullFunc then DataPullFunc:InvokeServer("UpgradeTreadmill") end
            end)
        end
    end)

    -- Auto Claim
    task.spawn(function()
        while task.wait(3) do
            if not F.autoClaim then continue end
            pcall(function()
                if DataPullFunc then DataPullFunc:InvokeServer("ClaimRewards") end
            end)
        end
    end)

    -- Auto Return
    task.spawn(function()
        while task.wait(1) do
            if not F.autoReturn then continue end
            pcall(function()
                local _, hrp = char()
                if not hrp then return end
                local plot = WS:FindFirstChild("Plot")
                if plot then moveTo = plot:GetPivot().Position + Vector3.new(0,10,0) end
            end)
        end
    end)

    -- Auto Equip Best
    task.spawn(function()
        while task.wait(5) do
            if not F.autoEquipBest then continue end
            pcall(function()
                if DataPullFunc then DataPullFunc:InvokeServer("EquipBestPet") end
            end)
        end
    end)

    -- Auto Fuse
    task.spawn(function()
        while task.wait(10) do
            if not F.autoFuse then continue end
            pcall(function()
                if DataPullFunc then DataPullFunc:InvokeServer("FusePets") end
            end)
        end
    end)

    -- Collect Index / Group / Offline
    task.spawn(function()
        while task.wait(5) do
            if not F.collectIndex then continue end
            pcall(function()
                if DataPullFunc then DataPullFunc:InvokeServer("CollectIndexRewards") end
            end)
        end
    end)
    task.spawn(function()
        while task.wait(5) do
            if not F.collectGroup then continue end
            pcall(function()
                if DataPullFunc then DataPullFunc:InvokeServer("CollectGroupRewards") end
            end)
        end
    end)
    task.spawn(function()
        while task.wait(5) do
            if not F.collectOffline then continue end
            pcall(function()
                if DataPullFunc then DataPullFunc:InvokeServer("CollectOfflineIncome") end
            end)
        end
    end)

    -- Speed
    task.spawn(function()
        while task.wait(0.01) do
            if not F.speed then continue end
            pcall(function()
                local _, hrp, hum = char()
                if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + hum.MoveDirection * 3
                end
            end)
        end
    end)

    -- Fly
    local fBV, fBG
    RunService.RenderStepped:Connect(function()
        if not F.fly then
            if fBV then fBV:Destroy() fBV = nil end
            if fBG then fBG:Destroy() fBG = nil end
            return
        end
        pcall(function()
            local _, hrp = char()
            if not hrp then return end
            if not fBV or fBV.Parent ~= hrp then
                if fBV then fBV:Destroy() end; if fBG then fBG:Destroy() end
                fBV = Instance.new("BodyVelocity"); fBV.MaxForce = Vector3.new(1e5,1e5,1e5); fBV.Velocity = Vector3.zero; fBV.Parent = hrp
                fBG = Instance.new("BodyGyro"); fBG.MaxTorque = Vector3.new(1e5,1e5,1e5); fBG.P = 1e4; fBG.Parent = hrp
            end
            local cam = WS.CurrentCamera
            local mv = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
            fBV.Velocity = mv * CFG.FLY_SPEED
            fBG.CFrame = cam.CFrame
        end)
    end)

    -- ESP
    local espC = {}
    task.spawn(function()
        while task.wait(0.6) do
            if F.espEggs or F.espPets or F.espTraps then
                pcall(function()
                    for _, e in ipairs(scanEggs()) do
                        if F.espEggs and not espC[e] then
                            local r = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
                            if r then
                                local b = Instance.new("BoxHandleAdornment"); b.Adornee = r; b.AlwaysOnTop = true; b.Size = r.Size + Vector3.new(0.5,0.5,0.5); b.Color3 = C.gold; b.Transparency = 0.5; b.Parent = r; espC[e] = b
                            end
                        end
                    end
                    for _, p in ipairs(scanPets()) do
                        if F.espPets and not espC[p] then
                            local r = p:FindFirstChild("HumanoidRootPart") or p:FindFirstChildWhichIsA("BasePart")
                            if r then
                                local b = Instance.new("BoxHandleAdornment"); b.Adornee = r; b.AlwaysOnTop = true; b.Size = r.Size + Vector3.new(0.5,0.5,0.5); b.Color3 = C.cyan; b.Transparency = 0.5; b.Parent = r; espC[p] = b
                            end
                        end
                    end
                end)
            else
                for k, v in pairs(espC) do
                    if v and v.Parent then v:Destroy() end
                    espC[k] = nil
                end
            end
        end
    end)

    -- Full Bright
    task.spawn(function()
        while task.wait(1) do
            if F.fullBright then
                pcall(function()
                    LT.Ambient = Color3.fromRGB(255,255,255)
                    LT.OutdoorAmbient = Color3.fromRGB(255,255,255)
                    LT.Brightness = 2; LT.ClockTime = 14; LT.FogEnd = 1e6
                end)
            end
        end
    end)

    -- Anti-AFK
    LP.Idled:Connect(function()
        if F.antiAfk and VU then
            pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
        end
    end)

    -- Server Hop
    task.spawn(function()
        while task.wait(30) do
            if not F.serverHop then continue end
            pcall(function()
                local HttpService = game:GetService("HttpService")
                local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"))
                if servers and servers.data then
                    for _, s in ipairs(servers.data) do
                        if s.playing < s.maxPlayers and s.id ~= game.JobId then
                            TS:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                            return
                        end
                    end
                end
            end)
        end
    end)

    -- Tab Content
    section(FarmT, "Auto Steal")
    toggle(FarmT, L.autoSteal, "autoSteal", function(v) if not v then moveTo = nil end end)
    toggle(FarmT, L.autoBigEgg, "autoBigEgg")
    toggle(FarmT, L.autoSecretEgg, "autoSecretEgg")
    toggle(FarmT, L.autoRarestEgg, "autoRarestEgg")
    section(FarmT, "Filters")
    toggle(FarmT, L.onlyHighValue, "onlyHighValue")
    toggle(FarmT, L.onlyMutations, "onlyMutations")
    toggle(FarmT, L.stealOnce, "stealOnce")
    toggle(FarmT, L.fastGrab, "fastGrab")
    toggle(FarmT, L.prediction, "prediction")
    toggle(FarmT, L.antiTraps, "antiTraps")
    toggle(FarmT, L.autoDropHeld, "autoDropHeld")
    toggle(FarmT, L.autoReturn, "autoReturn")
    section(FarmT, "Areas")
    dropdown(FarmT, L.selectedArea, {"All","Base","Snow","Volcano","Abyss Ocean","Cosmic","Sakura","Titan Temple","Prehistoric","Cherry Blossom"}, function(v) F.selectedArea = v end)
    dropdown(FarmT, L.selectedRarity, {"All","Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret"}, function(v) F.selectedRarity = v end)
    dropdown(FarmT, L.selectedMutation, {"All","Normal","Fractured","Shiny","Gold","Rainbow"}, function(v) F.selectedMutation = v end)
    slider(FarmT, L.minBigEggSize, 10, 1000, 100, function(v) F.minBigEggSize = v end)
    slider(FarmT, L.stealSpeed, 100, 500, CFG.STEAL_SPEED, function(v) CFG.STEAL_SPEED = v end)

    section(HatchT, "Auto Hatch")
    toggle(HatchT, L.autoHatch, "autoHatch")
    toggle(HatchT, L.autoHatchCosmic, "autoHatchCosmic")
    toggle(HatchT, L.autoHatchPrehistoric, "autoHatchPrehistoric")
    slider(HatchT, L.hatchDelay, 1, 10, CFG.HATCH_DELAY, function(v) CFG.HATCH_DELAY = v end)
    section(HatchT, "Auto Place")
    toggle(HatchT, L.autoPlace, "autoPlace")
    toggle(HatchT, L.placeHeld, "placeHeld")
    slider(HatchT, L.placeDelay, 1, 10, CFG.PLACE_DELAY, function(v) CFG.PLACE_DELAY = v end)

    section(SellT, "Auto Sell")
    toggle(SellT, L.autoSell, "autoSell")
    toggle(SellT, L.protectFavorites, "protectFavorites")
    toggle(SellT, L.protectValuable, "protectValuable")
    section(SellT, "Treadmill & Upgrade")
    toggle(SellT, L.autoTreadmill, "autoTreadmill")
    toggle(SellT, L.autoUpgrade, "autoUpgrade")
    toggle(SellT, L.autoBaseUpgrade, "autoBaseUpgrade")
    slider(SellT, L.upgradeDelay, 1, 10, CFG.UPGRADE_DELAY, function(v) CFG.UPGRADE_DELAY = v end)
    section(SellT, "Claim")
    toggle(SellT, L.autoClaim, "autoClaim")
    toggle(SellT, L.collectIndex, "collectIndex")
    toggle(SellT, L.collectGroup, "collectGroup")
    toggle(SellT, L.collectOffline, "collectOffline")
    section(SellT, "Equip & Fuse")
    toggle(SellT, L.autoEquipBest, "autoEquipBest")
    toggle(SellT, L.autoEquipTeam, "autoEquipTeam")
    toggle(SellT, L.autoFuse, "autoFuse")
    section(SellT, "Buy")
    toggle(SellT, L.autoBuyTrails, "autoBuyTrails")
    toggle(SellT, L.autoBuyProducts, "autoBuyProducts")
    toggle(SellT, L.hookProductID, "hookProductID")

    section(EventsT, "Rift & Events")
    toggle(EventsT, L.autoCosmic, "autoCosmic")
    toggle(EventsT, L.riftHunt, "riftHunt")
    toggle(EventsT, L.autoEventMonster, "autoEventMonster")
    toggle(EventsT, L.autoParasite, "autoParasite")
    toggle(EventsT, L.autoBoss, "autoBoss")
    toggle(EventsT, L.capture, "capture")

    section(VisualT, "ESP")
    toggle(VisualT, L.espEggs, "espEggs")
    toggle(VisualT, L.espPets, "espPets")
    toggle(VisualT, L.espTraps, "espTraps")
    section(VisualT, "Lighting")
    toggle(VisualT, L.fullBright, "fullBright")
    section(VisualT, "Pet Visual")
    toggle(VisualT, L.petMutation, "petMutation")
    toggle(VisualT, L.addVisualPet, "addVisualPet")
    toggle(VisualT, L.equipVisualPet, "equipVisualPet")

    section(MoveT, "Movement")
    toggle(MoveT, L.speed, "speed")
    toggle(MoveT, L.fly, "fly")
    toggle(MoveT, L.noclip, "noclip")
    toggle(MoveT, L.antiRagdoll, "antiRagdoll")
    toggle(MoveT, L.tpWalk, "tpWalk")
    slider(MoveT, L.flySpeed, 50, 300, CFG.FLY_SPEED, function(v) CFG.FLY_SPEED = v end)
    slider(MoveT, L.tpWalkSpeed, 50, 500, CFG.TP_WALK_SPEED, function(v) CFG.TP_WALK_SPEED = v end)

    section(PvpT, "PVP")
    toggle(PvpT, L.pvpEsp, "pvpEsp")
    toggle(PvpT, L.aimbot, "aimbot")

    section(MiscT, "Webhook")
    toggle(MiscT, L.webhook, "webhook")
    button(MiscT, "Set Webhook URL", function()
        local url = game:GetService("UserInputService"):GetTextFromUser("Enter Discord webhook URL:", "RedJ03N Webhook", "")
        if url and url ~= "" then F.webhookURL = url; SG:SetCore("SendNotification",{Title="RedJ03N",Text="Webhook saved!",Duration=3}) end
    end)
    button(MiscT, "Send Test Webhook", function()
        if F.webhookURL and F.webhookURL ~= "" then
            pcall(function()
                game:GetService("HttpService"):PostAsync(F.webhookURL, game:GetService("HttpService"):JSONEncode({content="🧪 Test from RedJ03N Steal an Egg v2"}))
            end)
            SG:SetCore("SendNotification",{Title="RedJ03N",Text="Webhook sent!",Duration=3})
        else
            SG:SetCore("SendNotification",{Title="RedJ03N",Text="No webhook URL set!",Duration=3})
        end
    end)
    section(MiscT, "Auto")
    toggle(MiscT, L.serverHop, "serverHop")
    toggle(MiscT, L.antiAfk, "antiAfk")
    section(MiscT, "Control")
    button(MiscT, L.stopAll, function()
        for k in pairs(F) do if k ~= "antiAfk" then F[k] = false end end
        moveTo = nil
        if fBV then fBV:Destroy() fBV = nil end; if fBG then fBG:Destroy() fBG = nil end
        SG:SetCore("SendNotification",{Title="RedJ03N",Text=L.stopAll,Duration=3})
    end)
    button(MiscT, L.discordBtn, function()
        pcall(function() setclipboard(DISCORD_LINK) end)
        SG:SetCore("SendNotification",{Title="RedJ03N",Text="Discord link copied!",Duration=3})
    end)
    button(MiscT, L.destroy, function() gui:Destroy() end)

    -- Header controls
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Main.Size = minimized and UDim2.new(0,660,0,56) or UDim2.new(0,660,0,470)
        Side.Visible = not minimized; Content.Visible = not minimized; Stat.Visible = not minimized
    end)
    CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

    -- Status line
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local c, hrp = char()
                local eggs = scanEggs(); local pets = scanPets()
                local tn = "none"
                if c then local t = c:FindFirstChildOfClass("Tool"); if t then tn = t.Name end end
                if #tn > 10 then tn = tn:sub(1,10)..".." end
                local nr = "-"
                if hrp and #eggs > 0 then
                    local bd = math.huge
                    for _, e in ipairs(eggs) do
                        local r = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
                        if r then local d = (hrp.Position - r.Position).Magnitude; if d < bd then bd = d end end
                    end
                    nr = math.floor(bd).."s"
                end
                local act = "idle"
                if F.autoSteal then act = "steal"
                elseif F.autoHatch then act = "hatch"
                elseif F.autoPlace then act = "place"
                elseif F.autoTreadmill then act = "treadmill"
                elseif F.riftHunt then act = "rift"
                elseif F.autoBoss then act = "boss"
                elseif F.autoCosmic then act = "cosmic"
                end
                Stat.Text = "  ["..act.."]  "..tn.."  ·  eggs:"..#eggs.."  ·  pets:"..#pets.."  ·  near:"..nr
            end)
        end
    end)

    SG:SetCore("SendNotification",{Title="RedJ03N v2",Text=L.ready,Duration=4})
end

showLoadingPopup()
