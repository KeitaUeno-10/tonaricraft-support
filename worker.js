const MAIL_FROM = 'noreply@tonaricraft.com';
const MAIL_TO = 'eg5737021414@gmail.com';

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}

function escapeHeader(value) {
  return String(value || '').replace(/[\r\n]+/g, ' ').trim();
}

function encodeHeader(value) {
  const clean = escapeHeader(value);
  if (/^[\x20-\x7e]*$/.test(clean)) return clean;
  const bytes = new TextEncoder().encode(clean);
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return `=?UTF-8?B?${btoa(binary)}?=`;
}

function encodeBody(value) {
  const bytes = new TextEncoder().encode(String(value || ''));
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/.{1,76}/g, '$&\r\n').trim();
}

function makeRawEmail({ name, email, category, message }) {
  const subject = `[TonariCraft] ${category}`;
  const body =
    `お名前: ${name}\n` +
    `メール: ${email}\n` +
    `相談内容: ${category}\n\n` +
    `${message}\n`;

  return [
    `From: TonariCraft Site <${MAIL_FROM}>`,
    `To: ${MAIL_TO}`,
    `Reply-To: ${encodeHeader(name)} <${escapeHeader(email)}>`,
    `Subject: ${encodeHeader(subject)}`,
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    'Content-Transfer-Encoding: base64',
    '',
    encodeBody(body),
  ].join('\r\n');
}

async function handleContact(request, env) {
  let form;
  try {
    form = await request.formData();
  } catch {
    return json({ ok: false, error: '送信内容を読み取れませんでした。' }, 400);
  }

  const trap = String(form.get('company') || '').trim();
  if (trap) return json({ ok: true });

  const name = String(form.get('name') || '').trim();
  const email = String(form.get('email') || '').trim();
  const category = String(form.get('category') || '').trim();
  const message = String(form.get('message') || '').trim();
  const consent = form.get('privacyConsent');

  if (!name || !email || !category || !message) {
    return json({ ok: false, error: '必須項目を入力してください。' }, 400);
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return json({ ok: false, error: 'メールアドレスの形式が正しくありません。' }, 400);
  }
  if (message.length > 5000) {
    return json({ ok: false, error: '相談内容が長すぎます。' }, 400);
  }
  if (consent !== 'on') {
    return json({ ok: false, error: 'プライバシーポリシーへの同意が必要です。' }, 400);
  }
  const createdAt = new Date().toISOString();

  if (!env.DB) {
    return json({ ok: false, error: '保存先の設定が未完了です。' }, 500);
  }

  await env.DB
    .prepare('INSERT INTO contact_messages (name, email, category, message, created_at) VALUES (?, ?, ?, ?, ?)')
    .bind(name, email, category, message, createdAt)
    .run();

  if (env.SEB) {
    const { EmailMessage } = await import('cloudflare:email');
    try {
      await env.SEB.send(new EmailMessage(MAIL_FROM, MAIL_TO, makeRawEmail({ name, email, category, message })));
    } catch (error) {
      console.error('[contact] email notification failed after D1 save', error);
    }
  }

  return json({ ok: true });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === 'POST' && url.pathname === '/api/contact') {
      return handleContact(request, env);
    }
    return env.ASSETS.fetch(request);
  },
};
