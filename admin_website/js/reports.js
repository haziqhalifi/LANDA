let currentOffset = 0;
const PAGE_SIZE = 50;
let currentTotal = 0;

// ── Toast notification ────────────────────────────────────────────────────────
function showToast(message, type = 'success') {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.className = `fixed top-4 right-4 z-50 px-5 py-3 rounded-xl shadow-lg text-sm font-semibold transition-all duration-300 ${
    type === 'success' ? 'bg-green-700 text-white' :
    type === 'error'   ? 'bg-red-600 text-white' :
                         'bg-gray-700 text-white'
  }`;
  toast.classList.remove('hidden');
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => toast.classList.add('hidden'), 3500);
}

// ── Confirm modal ─────────────────────────────────────────────────────────────
let _confirmCallback = null;
function showConfirm(message, onConfirm) {
  document.getElementById('confirm-message').textContent = message;
  document.getElementById('confirm-modal').classList.remove('hidden');
  _confirmCallback = onConfirm;
}
document.getElementById('confirm-ok-btn').addEventListener('click', () => {
  document.getElementById('confirm-modal').classList.add('hidden');
  if (_confirmCallback) { _confirmCallback(); _confirmCallback = null; }
});
document.getElementById('confirm-cancel-btn').addEventListener('click', () => {
  document.getElementById('confirm-modal').classList.add('hidden');
  _confirmCallback = null;
});

// ── Filters ───────────────────────────────────────────────────────────────────
function getFilters() {
  return {
    status: document.getElementById('status-filter').value,
    type:   document.getElementById('type-filter').value,
    search: document.getElementById('search-input').value.trim(),
  };
}

// ── Stats ─────────────────────────────────────────────────────────────────────
async function loadStats() {
  try {
    const stats = await api.getStats(getToken());
    if (!stats) return;
    document.getElementById('stat-total').textContent     = stats.total ?? 0;
    document.getElementById('stat-pending').textContent   = stats.pending ?? 0;
    document.getElementById('stat-validated').textContent = stats.validated ?? 0;
    document.getElementById('stat-rejected').textContent  = stats.rejected ?? 0;
    document.getElementById('stat-resolved').textContent  = stats.resolved ?? 0;
  } catch (_) {}
}

// ── Reports table ─────────────────────────────────────────────────────────────
async function loadReports() {
  const tbody = document.getElementById('reports-tbody');
  tbody.innerHTML = '<tr><td colspan="7" class="text-center py-10 text-gray-400">Loading...</td></tr>';
  try {
    const data = await api.getReports(getToken(), { ...getFilters(), limit: PAGE_SIZE, offset: currentOffset });
    if (!data) return;
    currentTotal = data.total ?? 0;
    renderReports(data.reports ?? []);
    updatePagination();
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-center py-10 text-red-400">${err.message}</td></tr>`;
  }
}

function renderReports(reports) {
  const tbody = document.getElementById('reports-tbody');
  if (!reports.length) {
    tbody.innerHTML = '<tr><td colspan="7" class="text-center py-10 text-gray-400">No reports found.</td></tr>';
    return;
  }

  const typeColors  = { flood: 'blue', landslide: 'amber', blocked_road: 'orange', medical_emergency: 'red' };
  const typeLabels  = { flood: 'Flood', landslide: 'Landslide', blocked_road: 'Blocked Road', medical_emergency: 'Medical' };
  const statusColors = { pending: 'yellow', validated: 'green', rejected: 'red', resolved: 'gray', expired: 'gray' };

  tbody.innerHTML = reports.map(r => {
    const tc   = typeColors[r.report_type] || 'gray';
    const sc   = statusColors[r.status] || 'gray';
    const tl   = typeLabels[r.report_type] || r.report_type;
    const date = new Date(r.created_at).toLocaleDateString('en-MY', { day: 'numeric', month: 'short', year: 'numeric' });
    const vuln = r.vulnerable_person ? '<span class="ml-1 text-red-600 font-bold" title="Vulnerable person">&#9888;</span>' : '';
    const desc = (r.description || '').slice(0, 60) + ((r.description || '').length > 60 ? '\u2026' : '');

    const canApprove = r.status === 'pending';
    const canReject  = r.status === 'pending' || r.status === 'validated';
    const canResolve = r.status === 'validated';

    return `<tr class="border-b border-gray-50 hover:bg-gray-50 transition-colors">
      <td class="px-4 py-3">
        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-${tc}-100 text-${tc}-700">${tl}</span>${vuln}
      </td>
      <td class="px-4 py-3 text-gray-700 text-sm max-w-32 truncate" title="${r.location_name}">${r.location_name}</td>
      <td class="px-4 py-3 text-gray-500 text-sm max-w-48 truncate" title="${r.description}">${desc}</td>
      <td class="px-4 py-3">
        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-${sc}-100 text-${sc}-700">${r.status}</span>
      </td>
      <td class="px-4 py-3 text-gray-700 text-sm font-medium">${r.vouch_count ?? 0}</td>
      <td class="px-4 py-3 text-gray-500 text-xs">${date}</td>
      <td class="px-4 py-3">
        <div class="flex gap-1 flex-wrap">
          ${canApprove ? `<button onclick="approveReport('${r.id}')"  class="px-2 py-1 text-xs bg-green-100 hover:bg-green-200 text-green-700 rounded-md font-medium transition-colors">Approve</button>` : ''}
          ${canReject  ? `<button onclick="openReject('${r.id}')"     class="px-2 py-1 text-xs bg-red-100 hover:bg-red-200 text-red-700 rounded-md font-medium transition-colors">Reject</button>` : ''}
          ${canResolve ? `<button onclick="resolveReport('${r.id}')"  class="px-2 py-1 text-xs bg-blue-100 hover:bg-blue-200 text-blue-700 rounded-md font-medium transition-colors">Resolve</button>` : ''}
          <button onclick="deleteReport('${r.id}')" class="px-2 py-1 text-xs bg-gray-100 hover:bg-gray-200 text-gray-600 rounded-md font-medium transition-colors">Delete</button>
        </div>
      </td>
    </tr>`;
  }).join('');
}

function updatePagination() {
  const from = currentOffset + 1;
  const to   = Math.min(currentOffset + PAGE_SIZE, currentTotal);
  document.getElementById('page-info').textContent = currentTotal > 0 ? `${from}\u2013${to} of ${currentTotal}` : 'No reports';
  document.getElementById('prev-btn').disabled = currentOffset === 0;
  document.getElementById('next-btn').disabled = currentOffset + PAGE_SIZE >= currentTotal;
}

// ── Actions ───────────────────────────────────────────────────────────────────
async function approveReport(id) {
  showConfirm('Approve this report as a legitimate incident? It will be marked as validated.', async () => {
    try {
      await api.approveReport(getToken(), id);
      showToast('Report approved successfully.', 'success');
      loadReports(); loadStats();
      // Prompt admin to send SMS alert to nearby people
      showSmsModal(id);
    } catch (err) { showToast(err.message, 'error'); }
  });
}

// ── SMS Alert Modal ────────────────────────────────────────────────────────────
function showSmsModal(reportId) {
  document.getElementById('sms-report-id').value = reportId;
  document.getElementById('sms-modal').classList.remove('hidden');
}

document.getElementById('sms-cancel-btn').addEventListener('click', () => {
  document.getElementById('sms-modal').classList.add('hidden');
});

document.getElementById('sms-send-btn').addEventListener('click', async () => {
  const id = document.getElementById('sms-report-id').value;
  document.getElementById('sms-modal').classList.add('hidden');
  try {
    const result = await api.sendSmsAlert(getToken(), id);
    const affected = result.total_affected ?? 0;
    const smsSent  = result.sms_sent ?? 0;
    const pushSent = result.push_sent ?? 0;
    showToast(
      affected === 0
        ? 'No registered users found within 10 km.'
        : `Alert sent — ${smsSent} SMS, ${pushSent} push (${affected} people reached).`,
      affected === 0 ? 'info' : 'success'
    );
  } catch (err) { showToast(err.message, 'error'); }
});

// ── Rescue Requests ───────────────────────────────────────────────────────────
async function loadRescueRequests() {
  const container = document.getElementById('rescue-list');
  try {
    const requests = await api.getRescueRequests(getToken());
    if (!requests || requests.length === 0) {
      container.innerHTML = '<p class="text-gray-400 text-sm text-center py-4">No active rescue requests.</p>';
      document.getElementById('rescue-badge').classList.add('hidden');
      return;
    }
    document.getElementById('rescue-badge').textContent = requests.length;
    document.getElementById('rescue-badge').classList.remove('hidden');
    container.innerHTML = requests.map(r => {
      const time = r.reply_at ? new Date(r.reply_at).toLocaleString('en-MY') : '—';
      const phone = r.phone_number || '—';
      const hasLoc = r.device_latitude != null && r.device_longitude != null;
      const mapsUrl = hasLoc
        ? `https://www.google.com/maps?q=${r.device_latitude},${r.device_longitude}`
        : null;
      return `
        <div class="flex items-start gap-3 p-3 bg-red-50 border border-red-200 rounded-xl">
          <div class="mt-0.5">
            <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-red-600 text-white text-xs font-bold">SOS</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-semibold text-red-800">${phone}</p>
            <p class="text-xs text-red-600 mt-0.5">Replied DANGER at ${time}</p>
            ${hasLoc
              ? `<a href="${mapsUrl}" target="_blank" class="inline-flex items-center gap-1 mt-1 text-xs text-blue-600 hover:underline font-medium">
                   <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                   View on Map (${r.device_latitude.toFixed(4)}, ${r.device_longitude.toFixed(4)})
                 </a>`
              : '<p class="text-xs text-gray-400 mt-1">Location not available</p>'}
          </div>
          <button onclick="acknowledgeRescue('${r.id}')"
            class="shrink-0 px-2 py-1 text-xs bg-green-100 hover:bg-green-200 text-green-700 rounded-lg font-medium transition-colors">
            Dispatched ✓
          </button>
        </div>`;
    }).join('');
  } catch (_) {
    container.innerHTML = '<p class="text-red-400 text-sm text-center py-4">Failed to load rescue requests.</p>';
  }
}

async function acknowledgeRescue(alertId) {
  try {
    await api.acknowledgeRescue(getToken(), alertId);
    showToast('Rescue team dispatched — request marked as handled.', 'success');
    loadRescueRequests();
  } catch (err) { showToast(err.message, 'error'); }
}

async function resolveReport(id) {
  showConfirm('Mark this report as resolved?', async () => {
    try {
      await api.resolveReport(getToken(), id);
      showToast('Report marked as resolved.', 'success');
      loadReports(); loadStats();
    } catch (err) { showToast(err.message, 'error'); }
  });
}

async function deleteReport(id) {
  showConfirm('Permanently delete this report? This cannot be undone.', async () => {
    try {
      await api.deleteReport(getToken(), id);
      showToast('Report deleted.', 'success');
      loadReports(); loadStats();
    } catch (err) { showToast(err.message, 'error'); }
  });
}

function openReject(id) {
  document.getElementById('reject-report-id').value = id;
  document.getElementById('reject-reason').value = '';
  document.getElementById('reject-modal').classList.remove('hidden');
}

document.getElementById('reject-cancel-btn').addEventListener('click', () => {
  document.getElementById('reject-modal').classList.add('hidden');
});

document.getElementById('reject-confirm-btn').addEventListener('click', async () => {
  const id     = document.getElementById('reject-report-id').value;
  const reason = document.getElementById('reject-reason').value.trim();
  if (!reason) { showToast('Please provide a rejection reason.', 'error'); return; }
  try {
    await api.rejectReport(getToken(), id, reason);
    document.getElementById('reject-modal').classList.add('hidden');
    showToast('Report rejected.', 'success');
    loadReports(); loadStats();
  } catch (err) { showToast(err.message, 'error'); }
});

// ── Controls ──────────────────────────────────────────────────────────────────
document.getElementById('refresh-btn').addEventListener('click', () => { currentOffset = 0; loadReports(); loadStats(); });
document.getElementById('prev-btn').addEventListener('click', () => { currentOffset = Math.max(0, currentOffset - PAGE_SIZE); loadReports(); });
document.getElementById('next-btn').addEventListener('click', () => { currentOffset += PAGE_SIZE; loadReports(); });

let searchTimer;
document.getElementById('search-input').addEventListener('input', () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => { currentOffset = 0; loadReports(); }, 400);
});
document.getElementById('status-filter').addEventListener('change', () => { currentOffset = 0; loadReports(); });
document.getElementById('type-filter').addEventListener('change',  () => { currentOffset = 0; loadReports(); });

// Initial load
loadStats();
loadReports();
