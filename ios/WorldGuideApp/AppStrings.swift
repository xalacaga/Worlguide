import Foundation
import WGCore

struct AppStrings {
    private let languageCode: String

    init(languageCode: String) {
        self.languageCode = languageCode.lowercased()
    }

    var exploreNow: String { value(fr: "Explore maintenant", en: "Explore now", es: "Explora ahora", de: "Jetzt entdecken", it: "Esplora ora", pt: "Explore agora", nl: "Nu ontdekken", ja: "今すぐ探索", zh: "立即探索", ar: "استكشف الآن") }
    var heroSubtitle: String { value(fr: "Des histoires courtes, des lieux proches, une voix qui te guide.", en: "Short stories, nearby places, and a voice to guide you.", es: "Historias cortas, lugares cercanos y una voz que te guía.", de: "Kurze Geschichten, Orte in der Nähe und eine Stimme, die dich führt.", it: "Storie brevi, luoghi vicini e una voce che ti guida.", pt: "Histórias curtas, lugares por perto e uma voz para guiar você.", nl: "Korte verhalen, plekken dichtbij en een stem die je gids is.", ja: "短いストーリー、近くの場所、案内してくれる音声。", zh: "短故事、附近地点，还有语音为你导览。", ar: "قصص قصيرة، أماكن قريبة، وصوت يرشدك.") }
    var view: String { value(fr: "Vue", en: "View", es: "Vista", de: "Ansicht", it: "Vista", pt: "Vista", nl: "Weergave", ja: "表示", zh: "视图", ar: "العرض") }
    var settings: String { value(fr: "Réglages", en: "Settings", es: "Ajustes", de: "Einstellungen", it: "Impostazioni", pt: "Configurações", nl: "Instellingen", ja: "設定", zh: "设置", ar: "الإعدادات") }
    var filter: String { value(fr: "Filtre", en: "Filter", es: "Filtro", de: "Filter", it: "Filtro", pt: "Filtro", nl: "Filter", ja: "フィルター", zh: "筛选", ar: "تصفية") }
    var allPOI: String { value(fr: "Tous", en: "All", es: "Todos", de: "Alle", it: "Tutti", pt: "Todos", nl: "Alles", ja: "すべて", zh: "全部", ar: "الكل") }
    var wikipediaPOI: String { value(fr: "Wikipedia", en: "Wikipedia", es: "Wikipedia", de: "Wikipedia", it: "Wikipedia", pt: "Wikipedia", nl: "Wikipedia", ja: "Wikipedia", zh: "Wikipedia", ar: "ويكيبيديا") }
    var completePOI: String { value(fr: "Complet", en: "Complete", es: "Completo", de: "Komplett", it: "Completo", pt: "Completo", nl: "Compleet", ja: "完全", zh: "完整", ar: "كامل") }
    var list: String { value(fr: "Liste", en: "List", es: "Lista", de: "Liste", it: "Lista", pt: "Lista", nl: "Lijst", ja: "リスト", zh: "列表", ar: "قائمة") }
    var map: String { value(fr: "Carte", en: "Map", es: "Mapa", de: "Karte", it: "Mappa", pt: "Mapa", nl: "Kaart", ja: "地図", zh: "地图", ar: "خريطة") }
    var youAreHere: String { value(fr: "Vous êtes ici", en: "You are here", es: "Estás aquí", de: "Du bist hier", it: "Sei qui", pt: "Você está aqui", nl: "Je bent hier", ja: "現在地", zh: "你在这里", ar: "أنت هنا") }
    var nearby: String { value(fr: "Autour", en: "Nearby", es: "Cerca", de: "In der Nähe", it: "Vicino", pt: "Perto", nl: "Dichtbij", ja: "周辺", zh: "附近", ar: "قريب") }
    var smartWalk: String { value(fr: "Balade", en: "Walk", es: "Paseo", de: "Tour", it: "Passeggiata", pt: "Passeio", nl: "Wandeling", ja: "散歩", zh: "漫步", ar: "جولة") }
    var travelJournal: String { value(fr: "Carnet", en: "Journal", es: "Diario", de: "Journal", it: "Diario", pt: "Diário", nl: "Dagboek", ja: "旅日記", zh: "旅行日志", ar: "اليوميات") }
    var favorites: String { value(fr: "Favoris", en: "Favorites", es: "Favoritos", de: "Favoriten", it: "Preferiti", pt: "Favoritos", nl: "Favorieten", ja: "お気に入り", zh: "收藏", ar: "المفضلة") }
    var history: String { value(fr: "Historique", en: "History", es: "Historial", de: "Verlauf", it: "Cronologia", pt: "Histórico", nl: "Geschiedenis", ja: "履歴", zh: "历史", ar: "السجل") }
    var language: String { value(fr: "Langue", en: "Language", es: "Idioma", de: "Sprache", it: "Lingua", pt: "Idioma", nl: "Taal", ja: "言語", zh: "语言", ar: "اللغة") }
    var searchPrompt: String { value(fr: "Chercher un lieu", en: "Search a place", es: "Buscar un lugar", de: "Ort suchen", it: "Cerca un luogo", pt: "Buscar um lugar", nl: "Zoek een plek", ja: "場所を検索", zh: "搜索地点", ar: "ابحث عن مكان") }
    var addFavoritesEmpty: String { value(fr: "Ajoute des lieux en favori pour les retrouver ici.", en: "Add favorite places to find them here.", es: "Añade lugares favoritos para encontrarlos aquí.", de: "Füge Orte zu deinen Favoriten hinzu, um sie hier wiederzufinden.", it: "Aggiungi luoghi ai preferiti per ritrovarli qui.", pt: "Adicione lugares aos favoritos para encontrá-los aqui.", nl: "Voeg favoriete plekken toe om ze hier terug te vinden.", ja: "お気に入りに追加した場所がここに表示されます。", zh: "收藏地点后可在这里找到。", ar: "أضف أماكن إلى المفضلة لتجدها هنا.") }
    var historyEmpty: String { value(fr: "Ton historique apparaîtra après l'ouverture d'un lieu.", en: "Your history will appear after you open a place.", es: "Tu historial aparecerá después de abrir un lugar.", de: "Dein Verlauf erscheint, nachdem du einen Ort geöffnet hast.", it: "La cronologia apparirà dopo aver aperto un luogo.", pt: "Seu histórico aparecerá depois que você abrir um lugar.", nl: "Je geschiedenis verschijnt nadat je een plek opent.", ja: "場所を開くと履歴に表示されます。", zh: "打开地点后会显示在历史中。", ar: "سيظهر سجلك بعد فتح مكان.") }
    var loadingPlaces: String { value(fr: "Recherche des lieux autour de toi…", en: "Finding places around you…", es: "Buscando lugares a tu alrededor…", de: "Suche Orte in deiner Nähe…", it: "Cerco luoghi intorno a te…", pt: "Procurando lugares ao seu redor…", nl: "Plekken in je buurt zoeken…", ja: "近くの場所を検索中…", zh: "正在查找你附近的地点…", ar: "جار البحث عن أماكن حولك…") }
    var searchingPlaces: String { value(fr: "Recherche mondiale…", en: "Searching worldwide…", es: "Buscando en todo el mundo…", de: "Weltweite Suche…", it: "Ricerca mondiale…", pt: "Buscando no mundo todo…", nl: "Wereldwijd zoeken…", ja: "世界中を検索中…", zh: "正在全球搜索…", ar: "جار البحث عالميًا…") }
    var noPOI: String { value(fr: "Aucun POI trouvé dans ce rayon.", en: "No places found in this radius.", es: "No se encontraron lugares en este radio.", de: "Keine Orte in diesem Radius gefunden.", it: "Nessun luogo trovato in questo raggio.", pt: "Nenhum lugar encontrado neste raio.", nl: "Geen plekken gevonden binnen deze straal.", ja: "この範囲には場所が見つかりません。", zh: "此范围内未找到地点。", ar: "لم يتم العثور على أماكن ضمن هذا النطاق.") }
    var noWalkResult: String { value(fr: "Aucun arrêt assez pertinent pour cette balade.", en: "No good stop for this walk yet.", es: "Aún no hay paradas adecuadas para este paseo.", de: "Noch kein passender Halt für diese Tour.", it: "Nessuna tappa adatta per questa passeggiata.", pt: "Nenhuma parada boa para este passeio ainda.", nl: "Nog geen goede stop voor deze wandeling.", ja: "この散歩に合う立ち寄り先はまだありません。", zh: "暂时没有适合这次漫步的站点。", ar: "لا توجد محطة مناسبة لهذه الجولة بعد.") }
    func noSearchResult(_ query: String) -> String { format(fr: "Aucun résultat pour « %@ ».", en: "No results for \"%@\".", es: "Sin resultados para « %@ ».", de: "Keine Ergebnisse für \"%@\".", it: "Nessun risultato per \"%@\".", pt: "Nenhum resultado para \"%@\".", nl: "Geen resultaten voor \"%@\".", ja: "「%@」の結果はありません。", zh: "没有“%@”的结果。", ar: "لا توجد نتائج لـ \"%@\".", query) }
    func exploringPlace(_ placeName: String) -> String { format(fr: "Tu explores : %@", en: "Exploring: %@", es: "Explorando: %@", de: "Du erkundest: %@", it: "Stai esplorando: %@", pt: "Explorando: %@", nl: "Je verkent: %@", ja: "探索中：%@", zh: "正在探索：%@", ar: "تستكشف: %@", placeName) }
    var returnToMyLocation: String { value(fr: "Ma position", en: "My location", es: "Mi ubicación", de: "Mein Standort", it: "La mia posizione", pt: "Minha localização", nl: "Mijn locatie", ja: "現在地", zh: "我的位置", ar: "موقعي") }
    var retry: String { value(fr: "Réessayer", en: "Retry", es: "Reintentar", de: "Erneut versuchen", it: "Riprova", pt: "Tentar novamente", nl: "Opnieuw proberen", ja: "再試行", zh: "重试", ar: "حاول مجددًا") }
    var close: String { value(fr: "Fermer", en: "Close", es: "Cerrar", de: "Schließen", it: "Chiudi", pt: "Fechar", nl: "Sluiten", ja: "閉じる", zh: "关闭", ar: "إغلاق") }
    var back: String { value(fr: "Retour", en: "Back", es: "Volver", de: "Zurück", it: "Indietro", pt: "Voltar", nl: "Terug", ja: "戻る", zh: "返回", ar: "رجوع") }
    var offlineResults: String { value(fr: "Mode offline : derniers lieux enregistrés affichés.", en: "Offline mode: showing your last saved places.", es: "Modo offline: se muestran tus últimos lugares guardados.", de: "Offline-Modus: zuletzt gespeicherte Orte werden angezeigt.", it: "Modalità offline: mostro gli ultimi luoghi salvati.", pt: "Modo offline: exibindo seus últimos lugares salvos.", nl: "Offline modus: je laatst opgeslagen plekken worden getoond.", ja: "オフラインモード：最後に保存した場所を表示しています。", zh: "离线模式：显示上次保存的地点。", ar: "وضع عدم الاتصال: يتم عرض آخر الأماكن المحفوظة.") }
    var nearbyAlerts: String { value(fr: "Alertes proches", en: "Nearby alerts", es: "Alertas cercanas", de: "Nahe Alerts", it: "Avvisi vicini", pt: "Alertas próximas", nl: "Alerts dichtbij", ja: "近くの通知", zh: "附近提醒", ar: "تنبيهات قريبة") }
    var configuration: String { value(fr: "Configuration", en: "Configuration", es: "Configuración", de: "Konfiguration", it: "Configurazione", pt: "Configuração", nl: "Configuratie", ja: "設定", zh: "配置", ar: "الإعدادات") }
    var duration: String { value(fr: "Durée", en: "Duration", es: "Duración", de: "Dauer", it: "Durata", pt: "Duração", nl: "Duur", ja: "所要時間", zh: "时长", ar: "المدة") }
    var mood: String { value(fr: "Envie", en: "Mood", es: "Ganas", de: "Stimmung", it: "Umore", pt: "Vontade", nl: "Zin", ja: "気分", zh: "偏好", ar: "المزاج") }
    var weather: String { value(fr: "Météo", en: "Weather", es: "Tiempo", de: "Wetter", it: "Meteo", pt: "Clima", nl: "Weer", ja: "天気", zh: "天气", ar: "الطقس") }
    var manualWeather: String { value(fr: "Météo manuelle", en: "Manual weather", es: "Tiempo manual", de: "Manuelles Wetter", it: "Meteo manuale", pt: "Clima manual", nl: "Handmatig weer", ja: "手動の天気", zh: "手动天气", ar: "طقس يدوي") }
    var loadingWeather: String { value(fr: "Météo en direct…", en: "Loading live weather…", es: "Cargando tiempo en vivo…", de: "Live-Wetter wird geladen…", it: "Meteo live in caricamento…", pt: "Carregando clima ao vivo…", nl: "Live weer laden…", ja: "ライブ天気を読み込み中…", zh: "正在加载实时天气…", ar: "جار تحميل الطقس المباشر…") }
    var refreshWeather: String { value(fr: "Actualiser la météo", en: "Refresh weather", es: "Actualizar tiempo", de: "Wetter aktualisieren", it: "Aggiorna meteo", pt: "Atualizar clima", nl: "Weer vernieuwen", ja: "天気を更新", zh: "刷新天气", ar: "تحديث الطقس") }
    var weatherFailure: String { value(fr: "Météo live indisponible, réglage manuel conservé.", en: "Live weather unavailable, keeping manual setting.", es: "Tiempo en vivo no disponible; se conserva el ajuste manual.", de: "Live-Wetter nicht verfügbar, manuelle Einstellung bleibt.", it: "Meteo live non disponibile, mantengo l'impostazione manuale.", pt: "Clima ao vivo indisponível; mantendo ajuste manual.", nl: "Live weer niet beschikbaar, handmatige instelling blijft.", ja: "ライブ天気は利用できません。手動設定を維持します。", zh: "实时天气不可用，保留手动设置。", ar: "الطقس المباشر غير متاح، سيتم الاحتفاظ بالإعداد اليدوي.") }
    var energy: String { value(fr: "Énergie", en: "Energy", es: "Energía", de: "Energie", it: "Energia", pt: "Energia", nl: "Energie", ja: "元気度", zh: "精力", ar: "الطاقة") }
    var context: String { value(fr: "Contexte", en: "Context", es: "Contexto", de: "Kontext", it: "Contesto", pt: "Contexto", nl: "Context", ja: "状況", zh: "情境", ar: "السياق") }
    var smartWalkSubtitle: String { value(fr: "Un mini-parcours adapté à ton temps, ton envie et le moment.", en: "A mini route adapted to your time, mood, and context.", es: "Una mini ruta adaptada a tu tiempo, ganas y contexto.", de: "Eine kurze Route passend zu Zeit, Stimmung und Kontext.", it: "Un mini percorso adattato a tempo, umore e contesto.", pt: "Uma mini rota ajustada ao tempo, vontade e contexto.", nl: "Een korte route aangepast aan tijd, zin en context.", ja: "時間、気分、状況に合わせた小さなルート。", zh: "根据时间、偏好和情境生成的小路线。", ar: "مسار قصير يناسب وقتك ومزاجك والسياق.") }
    var suggestedWalk: String { value(fr: "Proposée", en: "Suggested", es: "Sugerida", de: "Vorschlag", it: "Suggerita", pt: "Sugerida", nl: "Voorgesteld", ja: "提案", zh: "推荐", ar: "مقترحة") }
    var customWalk: String { value(fr: "Ma balade", en: "My walk", es: "Mi paseo", de: "Meine Tour", it: "La mia passeggiata", pt: "Meu passeio", nl: "Mijn wandeling", ja: "自分の散歩", zh: "我的路线", ar: "جولتي") }
    var customWalkSubtitle: String { value(fr: "Choisis tes arrêts : le tracé, les distances et le temps viennent de Plans.", en: "Pick your stops: the route, distances, and time come from Maps.", es: "Elige tus paradas: ruta, distancias y tiempo vienen de Mapas.", de: "Wähle deine Stopps: Route, Distanzen und Zeit kommen aus Karten.", it: "Scegli le tappe: percorso, distanze e tempo arrivano da Mappe.", pt: "Escolha as paradas: rota, distâncias e tempo vêm do Mapas.", nl: "Kies je haltes: route, afstanden en tijd komen uit Kaarten.", ja: "立ち寄り先を選択。経路、距離、時間はマップから取得します。", zh: "选择停靠点：路线、距离和时间来自地图。", ar: "اختر المحطات: المسار والمسافات والوقت من الخرائط.") }
    var chooseWalkStops: String { value(fr: "Choisir les POI", en: "Choose places", es: "Elegir lugares", de: "Orte wählen", it: "Scegli luoghi", pt: "Escolher lugares", nl: "Kies plekken", ja: "場所を選ぶ", zh: "选择地点", ar: "اختر الأماكن") }
    var departure: String { value(fr: "Départ", en: "Start", es: "Salida", de: "Start", it: "Partenza", pt: "Partida", nl: "Start", ja: "出発地", zh: "出发点", ar: "الانطلاق") }
    var pickAtLeastOneStop: String { value(fr: "Ajoute au moins un POI pour créer le circuit.", en: "Add at least one place to create the route.", es: "Añade al menos un lugar para crear la ruta.", de: "Füge mindestens einen Ort hinzu, um die Route zu erstellen.", it: "Aggiungi almeno un luogo per creare il percorso.", pt: "Adicione pelo menos um lugar para criar a rota.", nl: "Voeg minstens één plek toe om de route te maken.", ja: "ルートを作るには場所を1つ以上追加してください。", zh: "至少添加一个地点以创建路线。", ar: "أضف مكانًا واحدًا على الأقل لإنشاء المسار.") }
    var calculatingRoute: String { value(fr: "Calcul du tracé réel…", en: "Calculating real route…", es: "Calculando ruta real…", de: "Berechne echte Route…", it: "Calcolo percorso reale…", pt: "Calculando rota real…", nl: "Echte route berekenen…", ja: "実際の経路を計算中…", zh: "正在计算真实路线…", ar: "جار حساب المسار الفعلي…") }
    var calculatingAlternatives: String { value(fr: "Calcul des alternatives…", en: "Calculating alternatives…", es: "Calculando alternativas…", de: "Berechne Alternativen…", it: "Calcolo alternative…", pt: "Calculando alternativas…", nl: "Alternatieven berekenen…", ja: "代替ルートを計算中…", zh: "正在计算备选路线…", ar: "جار حساب البدائل…") }
    var routeUnavailable: String { value(fr: "Aucun tracé réel disponible pour ce circuit.", en: "No real route available for this circuit.", es: "No hay ruta real disponible para este circuito.", de: "Keine echte Route für diese Tour verfügbar.", it: "Nessun percorso reale disponibile.", pt: "Nenhuma rota real disponível.", nl: "Geen echte route beschikbaar.", ja: "このルートの実際の経路は利用できません。", zh: "此路线暂无真实路径。", ar: "لا يوجد مسار فعلي متاح.") }
    var cyclingAlternative: String { value(fr: "Vélo", en: "Cycling", es: "Bici", de: "Fahrrad", it: "Bici", pt: "Bicicleta", nl: "Fiets", ja: "自転車", zh: "骑行", ar: "دراجة") }
    var drivingAlternative: String { value(fr: "Voiture", en: "Driving", es: "Coche", de: "Auto", it: "Auto", pt: "Carro", nl: "Auto", ja: "車", zh: "驾车", ar: "سيارة") }
    var longWalkAlternative: String { value(fr: "Cette balade est longue à pied : le vélo ou la voiture peuvent être plus adaptés.", en: "This walk is long on foot: cycling or driving may be more suitable.", es: "Este paseo es largo a pie: quizá convenga ir en bici o coche.", de: "Diese Tour ist zu Fuß lang: Fahrrad oder Auto können passender sein.", it: "Questa passeggiata è lunga a piedi: bici o auto possono essere più adatte.", pt: "Este passeio é longo a pé: bicicleta ou carro podem ser melhores.", nl: "Deze wandeling is lang te voet: fiets of auto kan beter passen.", ja: "徒歩では長いルートです。自転車や車が適している場合があります。", zh: "步行路线较长，骑行或驾车可能更合适。", ar: "هذه الجولة طويلة مشيًا؛ قد تكون الدراجة أو السيارة أنسب.") }
    var openRouteInMaps: String { value(fr: "Ouvrir dans Plans", en: "Open in Maps", es: "Abrir en Mapas", de: "In Karten öffnen", it: "Apri in Mappe", pt: "Abrir no Mapas", nl: "Open in Kaarten", ja: "マップで開く", zh: "在地图中打开", ar: "افتح في الخرائط") }
    var openNextStopInMaps: String { value(fr: "Ouvrir la prochaine étape dans Plans", en: "Open next stop in Maps", es: "Abrir próxima parada en Mapas", de: "Nächste Station in Karten öffnen", it: "Apri prossima tappa in Mappe", pt: "Abrir próxima parada no Mapas", nl: "Open volgende stop in Kaarten", ja: "次の目的地をマップで開く", zh: "在地图中打开下一站", ar: "افتح المحطة التالية في الخرائط") }
    var openEachTransitLeg: String { value(fr: "Transports étape par étape", en: "Transit leg by leg", es: "Transporte etapa por etapa", de: "ÖPNV Etappe für Etappe", it: "Trasporti tappa per tappa", pt: "Transporte etapa por etapa", nl: "OV per etappe", ja: "区間ごとに公共交通", zh: "逐段公交", ar: "النقل مرحلة بمرحلة") }
    var transitToNextStop: String { value(fr: "Transports vers la prochaine étape", en: "Transit to next stop", es: "Transporte a la próxima parada", de: "ÖPNV zur nächsten Station", it: "Trasporti alla prossima tappa", pt: "Transporte até a próxima parada", nl: "OV naar volgende stop", ja: "次の目的地へ公共交通", zh: "公交前往下一站", ar: "النقل إلى المحطة التالية") }
    var addToWalk: String { value(fr: "Ajouter à la balade", en: "Add to walk", es: "Añadir al paseo", de: "Zur Tour hinzufügen", it: "Aggiungi alla passeggiata", pt: "Adicionar ao passeio", nl: "Toevoegen aan wandeling", ja: "散歩に追加", zh: "添加到路线", ar: "أضف إلى الجولة") }
    var removeFromWalk: String { value(fr: "Retirer de la balade", en: "Remove from walk", es: "Quitar del paseo", de: "Aus Tour entfernen", it: "Rimuovi dalla passeggiata", pt: "Remover do passeio", nl: "Verwijderen uit wandeling", ja: "散歩から削除", zh: "从路线移除", ar: "إزالة من الجولة") }
    var clearWalk: String { value(fr: "Vider la balade", en: "Clear walk", es: "Vaciar paseo", de: "Tour leeren", it: "Svuota passeggiata", pt: "Limpar passeio", nl: "Wandeling wissen", ja: "散歩をクリア", zh: "清空路线", ar: "مسح الجولة") }
    var estimatedWalk: String { value(fr: "Estimation", en: "Estimate", es: "Estimación", de: "Schätzung", it: "Stima", pt: "Estimativa", nl: "Schatting", ja: "目安", zh: "估计", ar: "تقدير") }
    var distanceWalked: String { value(fr: "Distance", en: "Distance", es: "Distancia", de: "Distanz", it: "Distanza", pt: "Distância", nl: "Afstand", ja: "距離", zh: "距离", ar: "المسافة") }
    var export: String { value(fr: "Exporter", en: "Export", es: "Exportar", de: "Exportieren", it: "Esporta", pt: "Exportar", nl: "Exporteren", ja: "書き出す", zh: "导出", ar: "تصدير") }
    var clearHistory: String { value(fr: "Supprimer l’historique", en: "Clear history", es: "Borrar historial", de: "Verlauf löschen", it: "Cancella cronologia", pt: "Limpar histórico", nl: "Geschiedenis wissen", ja: "履歴を消去", zh: "清除历史", ar: "مسح السجل") }
    var journalEmpty: String { value(fr: "Ton carnet se remplira quand tu ouvriras des lieux pendant la journée.", en: "Your journal fills up as you open places during the day.", es: "Tu diario se llenará al abrir lugares durante el día.", de: "Dein Journal füllt sich, wenn du tagsüber Orte öffnest.", it: "Il diario si riempie quando apri luoghi durante la giornata.", pt: "Seu diário aparece conforme você abre lugares no dia.", nl: "Je dagboek vult zich wanneer je plekken opent.", ja: "日中に場所を開くと旅日記が作られます。", zh: "当天打开地点后，旅行日志会自动生成。", ar: "تمتلئ اليوميات عند فتح أماكن خلال اليوم.") }
    func nearbyNotificationBody(_ poiName: String) -> String { format(fr: "Tu es près de %@. Ouvre WorldGuide pour découvrir le lieu.", en: "You're near %@. Open WorldGuide to discover it.", es: "Estás cerca de %@. Abre WorldGuide para descubrirlo.", de: "Du bist in der Nähe von %@. Öffne WorldGuide, um den Ort zu entdecken.", it: "Sei vicino a %@. Apri WorldGuide per scoprirlo.", pt: "Você está perto de %@. Abra o WorldGuide para descobrir.", nl: "Je bent dichtbij %@. Open WorldGuide om deze plek te ontdekken.", ja: "%@の近くにいます。WorldGuideで見てみましょう。", zh: "你在%@附近。打开 WorldGuide 了解它。", ar: "أنت بالقرب من %@. افتح WorldGuide لاكتشافه.", poiName) }
    var aroundYou: String { value(fr: "Autour de toi", en: "Around you", es: "A tu alrededor", de: "Um dich herum", it: "Intorno a te", pt: "Ao seu redor", nl: "Om je heen", ja: "あなたの周辺", zh: "你附近", ar: "حولك") }
    var reading: String { value(fr: "Lecture", en: "Reading", es: "Lectura", de: "Lesemodus", it: "Lettura", pt: "Leitura", nl: "Lezen", ja: "読み方", zh: "阅读", ar: "القراءة") }
    var flash: String { value(fr: "Flash", en: "Flash", es: "Flash", de: "Kurz", it: "Flash", pt: "Flash", nl: "Kort", ja: "短縮", zh: "速览", ar: "سريع") }
    var complete: String { value(fr: "Complet", en: "Full", es: "Completo", de: "Vollständig", it: "Completo", pt: "Completo", nl: "Volledig", ja: "全文", zh: "完整", ar: "كامل") }
    var loadingContent: String { value(fr: "Chargement du contenu…", en: "Loading content…", es: "Cargando contenido…", de: "Inhalt wird geladen…", it: "Caricamento contenuto…", pt: "Carregando conteúdo…", nl: "Content laden…", ja: "コンテンツを読み込み中…", zh: "正在加载内容…", ar: "جار تحميل المحتوى…") }
    var noContent: String { value(fr: "Aucun contenu disponible pour ce POI.", en: "No content available for this place.", es: "No hay contenido disponible para este lugar.", de: "Für diesen Ort ist kein Inhalt verfügbar.", it: "Nessun contenuto disponibile per questo luogo.", pt: "Nenhum conteúdo disponível para este lugar.", nl: "Geen content beschikbaar voor deze plek.", ja: "この場所のコンテンツはありません。", zh: "此地点暂无内容。", ar: "لا يوجد محتوى متاح لهذا المكان.") }
    var chooseAngle: String { value(fr: "Choisis ton angle", en: "Pick your angle", es: "Elige tu enfoque", de: "Wähle deinen Blickwinkel", it: "Scegli il tuo punto di vista", pt: "Escolha seu foco", nl: "Kies je invalshoek", ja: "テーマを選ぶ", zh: "选择你的角度", ar: "اختر زاويتك") }
    var themes: String { value(fr: "Thèmes", en: "Themes", es: "Temas", de: "Themen", it: "Temi", pt: "Temas", nl: "Thema's", ja: "テーマ", zh: "主题", ar: "المواضيع") }
    var play: String { value(fr: "Écouter", en: "Listen", es: "Escuchar", de: "Anhören", it: "Ascolta", pt: "Ouvir", nl: "Luisteren", ja: "聞く", zh: "收听", ar: "استمع") }
    var directions: String { value(fr: "S'y rendre", en: "Directions", es: "Cómo llegar", de: "Route", it: "Indicazioni", pt: "Como chegar", nl: "Route", ja: "経路", zh: "路线", ar: "الاتجاهات") }
    var walkingDirections: String { value(fr: "À pied", en: "Walk", es: "A pie", de: "Zu Fuß", it: "A piedi", pt: "A pé", nl: "Lopen", ja: "徒歩", zh: "步行", ar: "مشياً") }
    var transitDirections: String { value(fr: "Transports", en: "Transit", es: "Transporte", de: "ÖPNV", it: "Trasporti", pt: "Transporte", nl: "OV", ja: "公共交通", zh: "公交", ar: "النقل") }
    var officialInfo: String { value(fr: "Infos officielles", en: "Official info", es: "Info oficial", de: "Offizielle Infos", it: "Info ufficiali", pt: "Info oficial", nl: "Officiele info", ja: "公式情報", zh: "官方信息", ar: "معلومات رسمية") }
    var loadingOfficialInfo: String { value(fr: "Recherche d'infos officielles…", en: "Finding official info…", es: "Buscando info oficial…", de: "Suche offizielle Infos…", it: "Cerco info ufficiali…", pt: "Buscando info oficial…", nl: "Officiele info zoeken…", ja: "公式情報を検索中…", zh: "正在查找官方信息…", ar: "جار البحث عن معلومات رسمية…") }
    var noOfficialInfo: String { value(fr: "Aucune source officielle exploitable trouvée pour ce POI.", en: "No usable official source found for this place.", es: "No se encontró una fuente oficial utilizable para este lugar.", de: "Keine nutzbare offizielle Quelle für diesen Ort gefunden.", it: "Nessuna fonte ufficiale utilizzabile trovata per questo luogo.", pt: "Nenhuma fonte oficial utilizável encontrada para este lugar.", nl: "Geen bruikbare officiele bron gevonden voor deze plek.", ja: "この場所の利用可能な公式情報は見つかりません。", zh: "未找到此地点可用的官方来源。", ar: "لم يتم العثور على مصدر رسمي قابل للاستخدام لهذا المكان.") }
    var externalContentFailure: String { value(fr: "Impossible de charger les infos officielles pour le moment.", en: "Unable to load official info right now.", es: "No se puede cargar la info oficial ahora.", de: "Offizielle Infos können gerade nicht geladen werden.", it: "Impossibile caricare le info ufficiali ora.", pt: "Não foi possível carregar a info oficial agora.", nl: "Kan officiele info nu niet laden.", ja: "現在、公式情報を読み込めません。", zh: "目前无法加载官方信息。", ar: "تعذر تحميل المعلومات الرسمية الآن.") }
    var searchOnline: String { value(fr: "Rechercher en ligne", en: "Search online", es: "Buscar en línea", de: "Online suchen", it: "Cerca online", pt: "Pesquisar online", nl: "Online zoeken", ja: "オンラインで検索", zh: "在线搜索", ar: "البحث عبر الإنترنت") }
    var practicalInfo: String { value(fr: "Infos pratiques", en: "Practical info", es: "Info práctica", de: "Praktische Infos", it: "Info pratiche", pt: "Info prática", nl: "Praktische info", ja: "実用情報", zh: "实用信息", ar: "معلومات عملية") }
    var officialWebsite: String { value(fr: "Site officiel", en: "Official website", es: "Sitio oficial", de: "Offizielle Website", it: "Sito ufficiale", pt: "Site oficial", nl: "Officiele website", ja: "公式サイト", zh: "官方网站", ar: "الموقع الرسمي") }
    var address: String { value(fr: "Adresse", en: "Address", es: "Dirección", de: "Adresse", it: "Indirizzo", pt: "Endereço", nl: "Adres", ja: "住所", zh: "地址", ar: "العنوان") }
    var openingHours: String { value(fr: "Horaires", en: "Hours", es: "Horarios", de: "Öffnungszeiten", it: "Orari", pt: "Horários", nl: "Openingstijden", ja: "営業時間", zh: "开放时间", ar: "ساعات العمل") }
    var price: String { value(fr: "Prix", en: "Price", es: "Precio", de: "Preis", it: "Prezzo", pt: "Preço", nl: "Prijs", ja: "料金", zh: "价格", ar: "السعر") }
    var phone: String { value(fr: "Téléphone", en: "Phone", es: "Teléfono", de: "Telefon", it: "Telefono", pt: "Telefone", nl: "Telefoon", ja: "電話", zh: "电话", ar: "الهاتف") }
    var translatedAutomatically: String { value(fr: "Traduction automatique", en: "Automatic translation", es: "Traducción automática", de: "Automatische Übersetzung", it: "Traduzione automatica", pt: "Tradução automática", nl: "Automatische vertaling", ja: "自動翻訳", zh: "自动翻译", ar: "ترجمة تلقائية") }
    var originalText: String { value(fr: "Texte original", en: "Original text", es: "Texto original", de: "Originaltext", it: "Testo originale", pt: "Texto original", nl: "Originele tekst", ja: "原文", zh: "原文", ar: "النص الأصلي") }
    var pause: String { value(fr: "Pause", en: "Pause", es: "Pausa", de: "Pause", it: "Pausa", pt: "Pausar", nl: "Pauze", ja: "一時停止", zh: "暂停", ar: "إيقاف مؤقت") }
    var stop: String { value(fr: "Stop", en: "Stop", es: "Detener", de: "Stopp", it: "Stop", pt: "Parar", nl: "Stop", ja: "停止", zh: "停止", ar: "إيقاف") }
    var resume: String { value(fr: "Reprendre", en: "Resume", es: "Reanudar", de: "Fortsetzen", it: "Riprendi", pt: "Retomar", nl: "Hervatten", ja: "再開", zh: "继续", ar: "استئناف") }
    var sources: String { value(fr: "Sources", en: "Sources", es: "Fuentes", de: "Quellen", it: "Fonti", pt: "Fontes", nl: "Bronnen", ja: "出典", zh: "来源", ar: "المصادر") }
    var noSources: String { value(fr: "Aucune source exploitable associée.", en: "No usable source attached.", es: "No hay fuente utilizable asociada.", de: "Keine nutzbare Quelle zugeordnet.", it: "Nessuna fonte utilizzabile associata.", pt: "Nenhuma fonte utilizável associada.", nl: "Geen bruikbare bron gekoppeld.", ja: "利用できる出典はありません。", zh: "没有可用来源。", ar: "لا يوجد مصدر قابل للاستخدام.") }
    var locationDenied: String { value(fr: "Localisation refusée — active-la dans Réglages pour voir les POI à proximité.", en: "Location denied — enable it in Settings to see nearby places.", es: "Ubicación denegada: actívala en Ajustes para ver lugares cercanos.", de: "Standort verweigert — aktiviere ihn in den Einstellungen, um Orte in der Nähe zu sehen.", it: "Posizione negata: attivala nelle Impostazioni per vedere i luoghi vicini.", pt: "Localização negada — ative nas Configurações para ver lugares próximos.", nl: "Locatie geweigerd — zet dit aan in Instellingen om plekken dichtbij te zien.", ja: "位置情報が拒否されています。設定で有効にすると近くの場所を表示できます。", zh: "定位被拒绝 — 请在设置中开启以查看附近地点。", ar: "تم رفض الموقع — فعّله من الإعدادات لرؤية الأماكن القريبة.") }
    var nearbyFailure: String { value(fr: "Impossible de trouver des POI à proximité pour le moment.", en: "Unable to find nearby places right now.", es: "No se pueden encontrar lugares cercanos ahora.", de: "Orte in der Nähe können gerade nicht gefunden werden.", it: "Impossibile trovare luoghi vicini al momento.", pt: "Não foi possível encontrar lugares próximos agora.", nl: "Kan nu geen plekken in de buurt vinden.", ja: "現在、近くの場所を見つけられません。", zh: "目前无法查找附近地点。", ar: "تعذر العثور على أماكن قريبة الآن.") }
    var placeSearchFailure: String { value(fr: "Impossible de lancer la recherche mondiale pour le moment.", en: "Unable to search worldwide right now.", es: "No se puede buscar en todo el mundo ahora.", de: "Die weltweite Suche ist gerade nicht möglich.", it: "Impossibile cercare nel mondo ora.", pt: "Não foi possível buscar no mundo todo agora.", nl: "Kan nu niet wereldwijd zoeken.", ja: "現在、世界検索を利用できません。", zh: "目前无法进行全球搜索。", ar: "تعذر البحث عالميًا الآن.") }
    var contentFailure: String { value(fr: "Impossible de charger le contenu pour ce POI.", en: "Unable to load content for this place.", es: "No se puede cargar el contenido de este lugar.", de: "Inhalt für diesen Ort kann nicht geladen werden.", it: "Impossibile caricare il contenuto per questo luogo.", pt: "Não foi possível carregar o conteúdo deste lugar.", nl: "Kan de content voor deze plek niet laden.", ja: "この場所のコンテンツを読み込めません。", zh: "无法加载此地点的内容。", ar: "تعذر تحميل محتوى هذا المكان.") }
    func fallbackLanguageNotice(_ displayName: String) -> String { format(fr: "Contenu indisponible dans votre langue — affiché en %@", en: "Content unavailable in your language — showing %@", es: "Contenido no disponible en tu idioma — se muestra en %@", de: "Inhalt in deiner Sprache nicht verfügbar — angezeigt auf %@", it: "Contenuto non disponibile nella tua lingua — mostrato in %@", pt: "Conteúdo indisponível no seu idioma — exibido em %@", nl: "Content niet beschikbaar in je taal — weergegeven in %@", ja: "あなたの言語では利用できません — %@で表示します", zh: "你的语言暂无内容 — 显示%@", ar: "المحتوى غير متاح بلغتك — يُعرض بـ %@", displayName) }

    func qualityLabel(score: Int) -> String {
        switch score {
        case 5...:
            return value(fr: "À voir", en: "Must see", es: "Imperdible", de: "Sehenswert", it: "Da vedere", pt: "Imperdível", nl: "Aanrader", ja: "必見", zh: "必看", ar: "يستحق المشاهدة")
        case 3...:
            return value(fr: "Photo + infos", en: "Photo + info", es: "Foto + info", de: "Foto + Infos", it: "Foto + info", pt: "Foto + info", nl: "Foto + info", ja: "写真 + 情報", zh: "照片 + 信息", ar: "صورة + معلومات")
        case 2...:
            return value(fr: "Bien identifié", en: "Well identified", es: "Bien identificado", de: "Gut erkannt", it: "Ben identificato", pt: "Bem identificado", nl: "Goed herkend", ja: "識別済み", zh: "已识别", ar: "محدد جيدًا")
        default:
            return value(fr: "Découverte", en: "Discovery", es: "Descubrimiento", de: "Entdeckung", it: "Scoperta", pt: "Descoberta", nl: "Ontdekking", ja: "発見", zh: "发现", ar: "اكتشاف")
        }
    }

    func sourceTitle(_ sourceKind: Provenance.SourceKind) -> String {
        switch sourceKind {
        case .wikidata: return "Wikidata"
        case .wikipedia: return "Wikipedia"
        case .openStreetMap: return "OpenStreetMap"
        case .institutional:
            return value(fr: "Institutionnel", en: "Institutional", es: "Institucional", de: "Institutionell", it: "Istituzionale", pt: "Institucional", nl: "Institutioneel", ja: "機関", zh: "机构", ar: "مؤسسي")
        }
    }

    func listModeTitle(_ mode: NearbyPOIViewModel.ListMode) -> String {
        switch mode {
        case .nearby: return nearby
        case .smartWalk: return smartWalk
        case .journal: return travelJournal
        case .favorites: return favorites
        case .history: return history
        }
    }

    func walkDesireTitle(_ desire: NearbyPOIViewModel.WalkDesire) -> String {
        switch desire {
        case .balanced: return value(fr: "Mix malin", en: "Smart mix", es: "Mezcla inteligente", de: "Smart Mix", it: "Mix smart", pt: "Mix esperto", nl: "Slimme mix", ja: "おまかせ", zh: "智能组合", ar: "مزيج ذكي")
        case .monuments: return value(fr: "Monuments", en: "Monuments", es: "Monumentos", de: "Monumente", it: "Monumenti", pt: "Monumentos", nl: "Monumenten", ja: "記念碑", zh: "纪念建筑", ar: "معالم")
        case .streetArt: return value(fr: "Street art", en: "Street art", es: "Arte urbano", de: "Street Art", it: "Street art", pt: "Arte urbana", nl: "Street art", ja: "ストリートアート", zh: "街头艺术", ar: "فن الشارع")
        case .unusual: return value(fr: "Insolite", en: "Unusual", es: "Insólito", de: "Ungewöhnlich", it: "Insolito", pt: "Inusitado", nl: "Ongewoon", ja: "珍スポット", zh: "奇特地点", ar: "غير مألوف")
        case .architecture: return value(fr: "Architecture", en: "Architecture", es: "Arquitectura", de: "Architektur", it: "Architettura", pt: "Arquitetura", nl: "Architectuur", ja: "建築", zh: "建筑", ar: "عمارة")
        case .darkHistory: return value(fr: "Histoire sombre", en: "Dark history", es: "Historia oscura", de: "Dunkle Geschichte", it: "Storia oscura", pt: "História sombria", nl: "Donkere geschiedenis", ja: "暗い歴史", zh: "暗黑历史", ar: "تاريخ مظلم")
        case .photoSpots: return value(fr: "Spots photo", en: "Photo spots", es: "Fotos", de: "Fotospots", it: "Spot foto", pt: "Fotos", nl: "Fotospots", ja: "写真スポット", zh: "拍照点", ar: "نقاط صور")
        }
    }

    func weatherMoodTitle(_ weather: NearbyPOIViewModel.WeatherMood) -> String {
        switch weather {
        case .clear: return value(fr: "Clair", en: "Clear", es: "Despejado", de: "Klar", it: "Sereno", pt: "Limpo", nl: "Helder", ja: "晴れ", zh: "晴朗", ar: "صاف")
        case .rain: return value(fr: "Pluie", en: "Rain", es: "Lluvia", de: "Regen", it: "Pioggia", pt: "Chuva", nl: "Regen", ja: "雨", zh: "雨天", ar: "مطر")
        case .hot: return value(fr: "Chaud", en: "Hot", es: "Calor", de: "Heiß", it: "Caldo", pt: "Calor", nl: "Warm", ja: "暑い", zh: "炎热", ar: "حار")
        }
    }

    func liveWeather(_ description: String) -> String {
        format(fr: "Météo live : %@", en: "Live weather: %@", es: "Tiempo en vivo: %@", de: "Live-Wetter: %@", it: "Meteo live: %@", pt: "Clima ao vivo: %@", nl: "Live weer: %@", ja: "ライブ天気：%@", zh: "实时天气：%@", ar: "الطقس المباشر: %@", description)
    }

    func energyLevelTitle(_ energy: NearbyPOIViewModel.EnergyLevel) -> String {
        switch energy {
        case .fresh: return value(fr: "En forme", en: "Fresh", es: "Con energía", de: "Fit", it: "In forma", pt: "Com energia", nl: "Fris", ja: "元気", zh: "精力充沛", ar: "نشيط")
        case .normal: return value(fr: "Normal", en: "Normal", es: "Normal", de: "Normal", it: "Normale", pt: "Normal", nl: "Normaal", ja: "普通", zh: "普通", ar: "عادي")
        case .low: return value(fr: "Fatigué", en: "Tired", es: "Cansado", de: "Müde", it: "Stanco", pt: "Cansado", nl: "Moe", ja: "疲れ気味", zh: "疲惫", ar: "متعب")
        }
    }

    func readingModeTitle(_ mode: NearbyPOIViewModel.ReadingMode) -> String {
        switch mode {
        case .short: return flash
        case .complete: return complete
        }
    }

    func poiFilterTitle(_ filter: NearbyPOIViewModel.POIFilter) -> String {
        switch filter {
        case .all: return allPOI
        case .wikipedia: return wikipediaPOI
        case .complete: return completePOI
        }
    }

    private func format(fr: String, en: String, es: String, de: String, it: String, pt: String, nl: String, ja: String, zh: String, ar: String, _ argument: String) -> String {
        String(format: value(fr: fr, en: en, es: es, de: de, it: it, pt: pt, nl: nl, ja: ja, zh: zh, ar: ar), argument)
    }

    private func value(fr: String, en: String, es: String, de: String, it: String, pt: String, nl: String, ja: String, zh: String, ar: String) -> String {
        if languageCode.hasPrefix("fr") { return fr }
        if languageCode.hasPrefix("es") { return es }
        if languageCode.hasPrefix("de") { return de }
        if languageCode.hasPrefix("it") { return it }
        if languageCode.hasPrefix("pt") { return pt }
        if languageCode.hasPrefix("nl") { return nl }
        if languageCode.hasPrefix("ja") { return ja }
        if languageCode.hasPrefix("zh") { return zh }
        if languageCode.hasPrefix("ar") { return ar }
        return en
    }
}
