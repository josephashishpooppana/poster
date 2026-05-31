/**
 * Google Apps Script for updating priest rows in the RCDC spreadsheet.
 *
 * Setup:
 * 1. Open the spreadsheet → Extensions → Apps Script
 * 2. Paste this file and save
 * 3. Deploy → New deployment → Web app
 *    - Execute as: Me
 *    - Who has access: Anyone
 * 4. Copy the /exec URL into PriestSheetSync.webAppUrl in the Flutter app
 */

const SPREADSHEET_ID = '174QqITzlKsmpF-15KtkccLkpYSzOKLqyi8eXpI_0oxM';
const BIRTHDAY_SHEET_GID = 1721766266;
const ORDINATION_SHEET_GID = 825888209;

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const sheetType = data.sheet;
    const originalKey = normalizeKey(data.originalKey || data.name || '');

    const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
    const sheet = sheetType === 'birthday'
      ? getSheetByGid(ss, BIRTHDAY_SHEET_GID)
      : getSheetByGid(ss, ORDINATION_SHEET_GID);

    const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
    const nameCol = headers.indexOf('Name') + 1;
    const dateCol = (sheetType === 'birthday'
      ? headers.indexOf('Born')
      : headers.indexOf('Ordination')) + 1;

    const lastRow = sheet.getLastRow();
    const names = sheet.getRange(2, nameCol, lastRow, 1).getValues();

    let targetRow = -1;
    for (let i = 0; i < names.length; i++) {
      if (normalizeKey(names[i][0]) === originalKey) {
        targetRow = i + 2;
        break;
      }
    }

    if (targetRow === -1) {
      return jsonResponse({ success: false, error: 'Row not found' });
    }

    setCell(sheet, targetRow, headers, 'Name', data.name);
    setCell(sheet, targetRow, headers, 'Designation', data.designation);
    setCell(sheet, targetRow, headers, 'Serving At', data.servingAt);
    setCell(sheet, targetRow, headers, 'Address', data.address);
    if (data.date && dateCol > 0) {
      sheet.getRange(targetRow, dateCol).setValue(data.date);
    }

    return jsonResponse({ success: true });
  } catch (err) {
    return jsonResponse({ success: false, error: String(err) });
  }
}

function getSheetByGid(ss, gid) {
  const sheets = ss.getSheets();
  for (let i = 0; i < sheets.length; i++) {
    if (sheets[i].getSheetId() === gid) return sheets[i];
  }
  throw new Error('Sheet not found for gid ' + gid);
}

function setCell(sheet, row, headers, headerName, value) {
  if (value === undefined || value === null) return;
  const col = headers.indexOf(headerName);
  if (col === -1) return;
  sheet.getRange(row, col + 1).setValue(value);
}

function normalizeKey(name) {
  const tokens = new Set([
    'rev', 'fr', 'dr', 'ddr', 'msgr', 'very', 'b', 'th', 'm', 'a', 'ph',
    'stl', 'std', 'scl', 'isc', 'dcl', 'dd', 'bd', 'mba', 'mth', 'mph',
    'mphil', 'ma', 'ba', 'bcom', 'bsc', 'soc', 'com', 'mcj', 'mhrm', 'lss',
    'pg', 'gha', 'dh', 'hm', 'llb',
  ]);
  return String(name || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter(function (part) { return part && !tokens.has(part); })
    .join('-');
}

function jsonResponse(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
