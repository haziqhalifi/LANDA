function getToken() {
  return localStorage.getItem('admin_token');
}

function isTokenExpired(token) {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp * 1000 < Date.now();
  } catch (_) {
    return true;
  }
}

function requireAuth() {
  const token = getToken();
  if (!token || isTokenExpired(token)) {
    localStorage.removeItem('admin_token');
    window.location.href = 'login.html?expired=1';
  }
}

function logout() {
  localStorage.removeItem('admin_token');
  window.location.href = 'login.html';
}
