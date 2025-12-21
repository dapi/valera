# frozen_string_literal: true

namespace :screenshots do
  desc "Generate dashboard screenshot for documentation"
  task dashboard: :environment do
    require "erb"
    require "fileutils"

    puts "Generating dashboard screenshot..."

    tenant = Tenant.first
    unless tenant
      puts "Error: No tenant found. Run db:seed first."
      exit 1
    end

    stats = DashboardStatsService.new(tenant, period: 7).call

    html = generate_dashboard_html(tenant, stats)
    html_path = Rails.root.join("tmp", "dashboard_preview.html")
    File.write(html_path, html)
    puts "HTML saved to #{html_path}"

    output_dir = Rails.root.join("docs", "screenshots")
    FileUtils.mkdir_p(output_dir)
    output_path = output_dir.join("dashboard-overview.png")

    screenshot_js = generate_screenshot_js(html_path, output_path)
    js_path = Rails.root.join("tmp", "screenshot_task.js")
    File.write(js_path, screenshot_js)

    puts "Taking screenshot with Playwright..."
    system("npx playwright install chromium --with-deps > /dev/null 2>&1") unless playwright_installed?

    result = system("node #{js_path}")
    if result
      puts "Screenshot saved to #{output_path}"
    else
      puts "Error: Failed to generate screenshot. Ensure Node.js and Playwright are installed."
      puts "Run: npm install playwright && npx playwright install chromium"
      exit 1
    end
  end

  def playwright_installed?
    system("npx playwright --version > /dev/null 2>&1")
  end

  def generate_screenshot_js(html_path, output_path)
    <<~JS
      const { chromium } = require('playwright');

      (async () => {
        const browser = await chromium.launch();
        const context = await browser.newContext({
          viewport: { width: 1400, height: 900 }
        });
        const page = await context.newPage();

        try {
          await page.goto('file://#{html_path}', {
            waitUntil: 'domcontentloaded',
            timeout: 10000
          });

          await page.screenshot({ path: '#{output_path}', fullPage: true });
          console.log('Screenshot saved successfully');
        } catch (e) {
          console.error('Error:', e.message);
          process.exit(1);
        }

        await browser.close();
      })();
    JS
  end

  def generate_dashboard_html(tenant, stats)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Dashboard - #{ERB::Util.html_escape(tenant.name)}</title>
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f3f4f6; padding: 2rem; }
          .container { max-width: 1200px; margin: 0 auto; }
          h1 { font-size: 1.5rem; font-weight: bold; color: #1f2937; margin-bottom: 1.5rem; }
          h2 { font-size: 1.125rem; font-weight: 600; color: #1f2937; margin-bottom: 1rem; }
          .grid { display: grid; gap: 1.5rem; }
          .grid-4 { grid-template-columns: repeat(4, 1fr); }
          .card { background: white; border-radius: 0.5rem; box-shadow: 0 1px 3px rgba(0,0,0,0.1); padding: 1.5rem; }
          .card-header { display: flex; justify-content: space-between; align-items: center; }
          .card-label { font-size: 0.875rem; font-weight: 500; color: #6b7280; }
          .card-icon { font-size: 1.5rem; }
          .card-value { font-size: 1.875rem; font-weight: bold; color: #1f2937; margin-top: 0.5rem; }
          .card-meta { font-size: 0.875rem; margin-top: 0.25rem; }
          .text-green { color: #059669; }
          .text-gray { color: #9ca3af; }
          .mt-8 { margin-top: 2rem; }
          .flex { display: flex; }
          .gap-2 { gap: 0.5rem; }
          .justify-between { justify-content: space-between; }
          .items-center { align-items: center; }
          .mb-4 { margin-bottom: 1rem; }
          .btn-primary { padding: 0.25rem 0.75rem; font-size: 0.875rem; border-radius: 0.25rem; background: #3b82f6; color: white; }
          .btn-secondary { padding: 0.25rem 0.75rem; font-size: 0.875rem; border-radius: 0.25rem; background: #f3f4f6; color: #4b5563; }
          .chart-placeholder { height: 200px; background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%); border-radius: 0.5rem; display: flex; flex-direction: column; align-items: center; justify-content: center; color: #6366f1; font-weight: 500; }
          .dialog-card { border: 1px solid #e5e7eb; border-radius: 0.5rem; padding: 1rem; margin-bottom: 1rem; }
          .dialog-name { font-size: 0.875rem; font-weight: 500; color: #1f2937; margin-bottom: 0.75rem; }
          .message-list { padding-left: 0.5rem; border-left: 2px solid #e5e7eb; }
          .message { display: flex; gap: 0.5rem; align-items: flex-start; margin-bottom: 0.5rem; }
          .message-icon { font-size: 0.75rem; flex-shrink: 0; }
          .message-text { font-size: 0.875rem; color: #4b5563; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
          @media (max-width: 768px) { .grid-4 { grid-template-columns: 1fr 1fr; } }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>Обзор</h1>

          <div class="grid grid-4">
            <div class="card">
              <div class="card-header">
                <div class="card-label">Клиенты</div>
                <span class="card-icon">👥</span>
              </div>
              <div class="card-value">#{stats.clients_total}</div>
              <div class="card-meta">
                <span class="text-green">+#{stats.clients_today} сегодня</span>
                <span class="text-gray"> • </span>
                <span class="text-green">+#{stats.clients_week} за неделю</span>
              </div>
            </div>

            <div class="card">
              <div class="card-header">
                <div class="card-label">Заявки</div>
                <span class="card-icon">📝</span>
              </div>
              <div class="card-value">#{stats.bookings_total}</div>
              <div class="card-meta text-green">+#{stats.bookings_today} сегодня</div>
            </div>

            <div class="card">
              <div class="card-header">
                <div class="card-label">Активные чаты</div>
                <span class="card-icon">💬</span>
              </div>
              <div class="card-value">#{stats.active_chats}</div>
              <div class="card-meta text-gray">за последние 24ч</div>
            </div>

            <div class="card">
              <div class="card-header">
                <div class="card-label">Сообщений сегодня</div>
                <span class="card-icon">📨</span>
              </div>
              <div class="card-value">#{stats.messages_today}</div>
            </div>
          </div>

          <div class="card mt-8">
            <div class="flex justify-between items-center mb-4">
              <h2>📈 Активность</h2>
              <div class="flex gap-2">
                <span class="btn-primary">7 дней</span>
                <span class="btn-secondary">30 дней</span>
              </div>
            </div>
            <div class="chart-placeholder">
              <div>График: #{stats.chart_data[:labels].first} - #{stats.chart_data[:labels].last}</div>
              <div>Всего сообщений: #{stats.chart_data[:values].sum}</div>
            </div>
          </div>

          <div class="card mt-8">
            <h2>🕐 Последние диалоги</h2>
            #{generate_dialogs_html(stats.recent_chats)}
          </div>
        </div>
      </body>
      </html>
    HTML
  end

  def generate_dialogs_html(chats)
    chats.map do |chat|
      messages_html = chat.messages.order(created_at: :desc).limit(4).reverse.map do |msg|
        icon = msg.role == "user" ? "👤" : "🤖"
        content = ERB::Util.html_escape(msg.content.to_s.truncate(60))
        "<div class='message'><span class='message-icon'>#{icon}</span><p class='message-text'>#{content}</p></div>"
      end.join("\n")

      <<~DIALOG
        <div class="dialog-card">
          <div class="dialog-name">#{ERB::Util.html_escape(chat.client.display_name)}</div>
          <div class="message-list">
            #{messages_html}
          </div>
        </div>
      DIALOG
    end.join("\n")
  end
end
