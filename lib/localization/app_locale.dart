mixin AppLocale {
  // General
  static const String appTitle = 'appTitle';
  static const String accountInformation = 'accountInformation';
  static const String loading = 'loading';
  static const String error = 'error';
  static const String retry = 'retry';
  static const String loggingOut = 'loggingOut';
  static const String logout = 'logout';
  static const String cancel = 'cancel';
  static const String confirmLogout = 'confirmLogout';
  static const String areYouSureLogout = 'areYouSureLogout';
  static const String redirectingToLogin = 'redirectingToLogin';
  static const String sessionExpired = 'sessionExpired';
  static const String unexpectedError = 'unexpectedError';
  static const String settings = 'settings';
  static const String languageSettings = 'languageSettings';
  static const String selectLanguage = 'selectLanguage';
  static const String themeSettings = 'themeSettings';
  static const String appTheme = 'appTheme';
  static const String changeAppTheme = 'changeAppTheme';
  static const String notificationSettings = 'notificationSettings';
  static const String pushNotifications = 'pushNotifications';
  static const String receiveNotifications = 'receiveNotifications';
  static const String accountSettings = 'accountSettings';
  static const String accountDetails = 'accountDetails';
  static const String manageAccount = 'manageAccount';
  static const String comingSoon = 'comingSoon';
  static const String helpAndSupport = 'helpAndSupport';
  static const String dashboard = 'dashboard';
  static const String editProfile = 'editProfile';
  static const String loadingUserData = 'loadingUserData';
  static const String noUserId = 'noUserId';
  static const String goToLogin = 'goToLogin';
  static const String errorFetchingUserId = 'errorFetchingUserId';
  static const String featureComingSoon = 'featureComingSoon';

  // Authentication
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String emailLabel = 'emailLabel';
  static const String passwordLabel = 'passwordLabel';
  static const String confirmPasswordLabel = 'confirmPasswordLabel';
  static const String loginError = 'loginError';
  static const String registerError = 'registerError';

  // Profile
  static const String profile = 'profile';
  static const String fullName = 'fullName';
  static const String phoneNumber = 'phoneNumber';
  static const String gender = 'gender';
  static const String nationalId = 'nationalId';
  static const String language = 'language';

  // ChargeNowDevicesScreen
  static const String searchForChargingStations = 'searchForChargingStations';
  static const String back = 'back';
  static const String moreOptions = 'moreOptions';
  static const String centerOnMyLocation = 'centerOnMyLocation';
  static const String refreshNearby = 'refreshNearby';
  static const String fetchingLocation = 'fetchingLocation';
  static const String findingNearbyStations = 'findingNearbyStations';
  static const String noStationsNearby = 'noStationsNearby';
  static const String networkError = 'networkError';
  static const String failedToLoadStations = 'failedToLoadStations';
  static const String failedToCenterMap = 'failedToCenterMap';
  static const String noStationsMatching = 'noStationsMatching';
  static const String clearSearch = 'clearSearch';

  // Charging Popup
  static const String chargingStarted = 'chargingStarted';
  static const String batteryLevel = 'batteryLevel';
  static const String chargingRate = 'chargingRate';
  static const String estimatedTime = 'estimatedTime';
  static const String sessionDuration = 'sessionDuration';
  static const String viewWallet = 'viewWallet';

  // English translations
  static const Map<String, dynamic> en = {
    // General
    appTitle: 'ChargeNow',
    accountInformation: 'Account Information',
    loading: 'Loading...',
    error: 'Error',
    retry: 'Retry',
    loggingOut: 'Logging out...',
    logout: 'Logout',
    cancel: 'Cancel',
    confirmLogout: 'Confirm Logout',
    areYouSureLogout: 'Are you sure you want to log out?',
    redirectingToLogin: 'Redirecting to login...',
    sessionExpired: 'Session expired. Please login again.',
    unexpectedError: 'An unexpected error occurred.',
    settings: 'Settings',
    languageSettings: 'Language Settings',
    selectLanguage: 'Select Language',
    themeSettings: 'Theme Settings',
    appTheme: 'App Theme',
    changeAppTheme: 'Change the look and feel of the app',
    notificationSettings: 'Notification Settings',
    pushNotifications: 'Push Notifications',
    receiveNotifications: 'Receive push notifications for updates',
    accountSettings: 'Account Settings',
    accountDetails: 'Wallet',
    manageAccount: 'Manage your account details',
    comingSoon: 'Coming soon',
    helpAndSupport: 'Help & Support',
    dashboard: 'Dashboard',
    editProfile: 'Edit Profile',
    loadingUserData: 'Loading user data...',
    noUserId: 'No user ID available. Redirecting to login...',
    goToLogin: 'Go to Login',
    errorFetchingUserId: 'Error fetching user ID: {error}',
    featureComingSoon: 'This feature is coming soon.',

    // Authentication
    login: 'Login',
    register: 'Register',
    forgotPassword: 'Forgot Password?',
    emailLabel: 'Email',
    passwordLabel: 'Password',
    confirmPasswordLabel: 'Confirm Password',
    loginError: 'Failed to login. Please check your credentials.',
    registerError: 'Failed to register. Please try again.',

    // Profile
    profile: 'Profile',
    fullName: 'Full Name',
    phoneNumber: 'Phone Number',
    gender: 'Gender',
    nationalId: 'National ID',
    language: 'Language',

    // ChargeNowDevicesScreen
    searchForChargingStations: 'Search for charging stations',
    back: 'Back',
    moreOptions: 'More options',
    centerOnMyLocation: 'Center on My Location',
    refreshNearby: 'Refresh Nearby',
    fetchingLocation: 'Fetching your location...',
    findingNearbyStations: 'Finding nearby stations...',
    noStationsNearby: 'No charging stations found nearby. Try zooming out or moving to another area.',
    networkError: 'Check your network connection and try again.',
    failedToLoadStations: 'Failed to load stations.',
    failedToCenterMap: 'Failed to center map. Please try again.',
    noStationsMatching: "No stations found matching '{query}'. Try a different search term.",
    clearSearch: 'Clear search',

    // Charging Popup
    chargingStarted: 'Charging Started',
    batteryLevel: 'Battery Level',
    chargingRate: 'Charging Rate',
    estimatedTime: 'Estimated Time to Full',
    sessionDuration: 'Session Duration',
    viewWallet: 'View Wallet',
  };

  // Swahili translations
  static const Map<String, dynamic> sw = {
    // General
    appTitle: 'ChargeNow',
    accountInformation: 'Maelezo ya Akaunti',
    loading: 'Inapakia...',
    error: 'Hitilafu',
    retry: 'Jaribu tena',
    loggingOut: 'Unatoka...',
    logout: 'Toka',
    cancel: 'Ghairi',
    confirmLogout: 'Thibitisha Kutoka',
    areYouSureLogout: 'Una uhakika unataka kutoka?',
    redirectingToLogin: 'Inaelekeza kwenye ukurasa wa kuingia...',
    sessionExpired: 'Kipindi kimeisha. Tafadhali ingia tena.',
    unexpectedError: 'Hitilafu isiyotarajiwa ilitokea.',
    settings: 'Mipangilio',
    languageSettings: 'Mipangilio ya Lugha',
    selectLanguage: 'Chagua Lugha',
    themeSettings: 'Mipangilio ya Mandhari',
    appTheme: 'Mandhari ya Programu',
    changeAppTheme: 'Badilisha mwonekano wa programu',
    notificationSettings: 'Mipangilio ya Arifa',
    pushNotifications: 'Arifa za Kushinikiza',
    receiveNotifications: 'Pokea arifa za kushinikiza kwa masasisho',
    accountSettings: 'Mipangilio ya Akaunti',
    accountDetails: 'Pesa',
    manageAccount: 'Simamia maelezo ya akaunti yako',
    comingSoon: 'Inakuja hivi karibuni',
    helpAndSupport: 'Msaada na Usaidizi',
    dashboard: 'Dashibodi',
    editProfile: 'Hariri Wasifu',
    loadingUserData: 'Inapakia data ya mtumiaji...',
    noUserId: 'Hakuna kitambulisho cha mtumiaji. Inaelekeza kwenye ukurasa wa kuingia...',
    goToLogin: 'Nenda kwenye Kuingia',
    errorFetchingUserId: 'Hitilafu katika kupata kitambulisho cha mtumiaji: {error}',
    featureComingSoon: 'Hii inakuja hivi karibuni.',

    // Authentication
    login: 'Ingia',
    register: 'Jisajili',
    forgotPassword: 'Umesahau Nywila?',
    emailLabel: 'Barua Pepe',
    passwordLabel: 'Nywila',
    confirmPasswordLabel: 'Thibitisha Nywila',
    loginError: 'Imeshindwa kuingia. Tafadhali angalia maelezo yako.',
    registerError: 'Imeshindwa kusajili. Tafadhali jaribu tena.',

    // Profile
    profile: 'Wasifu',
    fullName: 'Jina Kamili',
    phoneNumber: 'Namba ya Simu',
    gender: 'Jinsia',
    nationalId: 'Kitambulisho cha Taifa',
    language: 'Lugha',

    // ChargeNowDevicesScreen
    searchForChargingStations: 'Tafuta vituo vya kuchaji',
    back: 'Rudi',
    moreOptions: 'Chaguo zaidi',
    centerOnMyLocation: 'Weka katikati ya eneo langu',
    refreshNearby: 'Onyesha upya karibu',
    fetchingLocation: 'Inapata eneo lako...',
    findingNearbyStations: 'Inatafuta vituo vya karibu...',
    noStationsNearby: 'Hakuna vituo vya kuchaji vilivyopatikana karibu. Jaribu kukuza au kuhamia eneo lingine.',
    networkError: 'Angalia muunganisho wako wa mtandao na ujaribu tena.',
    failedToLoadStations: 'Imeshindwa kupakia vituo.',
    failedToCenterMap: 'Imeshindwa kuweka katikati ya ramani. Tafadhali jaribu tena.',
    noStationsMatching: "Hakuna vituo vilivyopatikana vinavyolingana na '{query}'. Jaribu neno tofauti la utafutaji.",
    clearSearch: 'Futa utafutaji',

    // Charging Popup
    chargingStarted: 'Kuchaji Kumeanza',
    batteryLevel: 'Kiwango cha Betri',
    chargingRate: 'Kiwango cha Kuchaji',
    estimatedTime: 'Muda wa Kukadiriwa hadi Ijae',
    sessionDuration: 'Muda wa Kipindi',
    viewWallet: 'Angalia Pesa',
  };
}