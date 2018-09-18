window.keycloakClient = {};

const keycloakConfig = {
  url: location.protocol + '//' + location.hostname + '/auth',
  realm: 'oli_security',
  clientId: 'admin_client',
};

var kc = null; 
var onLoginFailure = null;
var onLoginSuccess = null;
var onTokenUpdate = null;
var redirectUri = null;

function initialize(onLoginSuccessFunc, onLoginFailureFunc, onTokenUpdateFunc, redirectUriStr) {

  onLoginFailure = onLoginFailureFunc;
  onLoginSuccess = onLoginSuccessFunc;
  onTokenUpdate = onTokenUpdateFunc;
  redirectUri = redirectUriStr;

  login();
}

window.keycloakClient.initialize = initialize;

function forceLogin() {
  window.location = configuration.protocol + configuration.hostname;
}

function login() {
  
  kc = Keycloak(keycloakConfig);

  kc.init({ onLoad: 'login-required', checkLoginIframe: false }).success((authenticated) => {
    if (authenticated) {

      // Also, request asynchronously the user's profile from keycloak
      kc.loadUserProfile().success((profile) => {

        const logoutUrl = kc.createLogoutUrl({ redirectUri });
        const accountManagementUrl = kc.createAccountUrl();

        continuallyRefreshToken();

        onLoginSuccess(kc.token, profile, logoutUrl, accountManagementUrl);
      
      }).error(() => onLoginFailure());
      
    } else {
      // Requires inserting "http://<hostname>/*" in the Valid Redirect URIs entry
      // of the Content_client settings in the KeyCloak admin UI
      kc.login({ redirectUri });
    }
  });

}

function continuallyRefreshToken() {
  setTimeout(
    () => {
      refreshTokenIfInvalid(60)
        .then(validToken => validToken ? continuallyRefreshToken() : forceLogin());
    }, 
    30000);
}

const WITHIN_FIVE_SECONDS = 5;

function refreshTokenIfInvalid(within) {
  
  if (within === undefined) {
    within = WITHIN_FIVE_SECONDS;
  }

  if (kc.isTokenExpired(within)) {
    return new Promise((resolve, reject) => {
      kc.updateToken(within).success((refreshed) => {
        if (refreshed) {
          onTokenUpdate(kc.token);
          resolve(true);
        } else {
          resolve(true);
        }
      }).error(() => {
        resolve(false);
      });
    });
  } else {
    return Promise.resolve(true);
  }
}