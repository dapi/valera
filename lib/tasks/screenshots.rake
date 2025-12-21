# frozen_string_literal: true

namespace :screenshots do
  desc "Generate dashboard screenshot from running server"
  task dashboard: :environment do
    require "fileutils"

    puts "Generating dashboard screenshot from live server..."
    puts ""
    puts "IMPORTANT: Server must be started with HOST=lvh.me:"
    puts "  HOST=lvh.me bin/rails server"
    puts ""

    tenant = Tenant.first
    unless tenant
      puts "Error: No tenant found. Run db:seed first."
      exit 1
    end

    # Убедимся, что у owner есть пароль
    owner = tenant.owner
    unless owner.password_digest.present?
      puts "Setting password for tenant owner..."
      owner.update!(password: "password123")
    end

    output_dir = Rails.root.join("docs", "screenshots")
    FileUtils.mkdir_p(output_dir)

    js_path = Rails.root.join("tmp", "screenshot_live.js")
    File.write(js_path, screenshot_js(tenant, output_dir))

    puts "Checking Playwright installation..."
    unless system("npx playwright --version > /dev/null 2>&1")
      puts "Installing Playwright..."
      system("npm install playwright && npx playwright install chromium")
    end

    puts "Taking screenshot..."
    puts "Tenant: #{tenant.name} (key: #{tenant.key})"
    puts "URL: http://#{tenant.key}.lvh.me:3000/"

    result = system("node #{js_path}")
    if result
      puts "Screenshots saved to #{output_dir}/"
    else
      puts "Error: Failed to generate screenshot."
      puts "Make sure Rails server is running with: HOST=lvh.me bin/rails server"
      exit 1
    end
  end

  private

  def screenshot_js(tenant, output_dir)
    <<~JS
      const { chromium } = require('playwright');

      (async () => {
        const browser = await chromium.launch();
        const context = await browser.newContext({
          viewport: { width: 1400, height: 1000 }
        });
        const page = await context.newPage();

        const tenantKey = '#{tenant.key}';
        const baseUrl = `http://${tenantKey}.lvh.me:3000`;
        const password = 'password123';

        try {
          console.log('Navigating to:', baseUrl);
          await page.goto(baseUrl, {
            waitUntil: 'networkidle',
            timeout: 30000
          });

          // Check if we need to login
          const passwordField = await page.$('input[type="password"], input[name="password"]');
          if (passwordField) {
            console.log('Logging in...');
            await passwordField.fill(password);

            const submitBtn = await page.$('button[type="submit"], input[type="submit"]');
            if (submitBtn) {
              await submitBtn.click();
              await page.waitForLoadState('networkidle');
              await page.waitForTimeout(2000); // Wait for chart to render
            }
          }

          // Screenshot 1: Dashboard with 7 days (default)
          console.log('Taking dashboard screenshot (7 days)...');
          await page.screenshot({
            path: '#{output_dir}/dashboard-overview.png',
            fullPage: true
          });
          console.log('Saved: dashboard-overview.png');

          // Screenshot 2: Switch to 30 days
          const period30Link = await page.$('a:has-text("30 дней")');
          if (period30Link) {
            console.log('Switching to 30 days...');
            await period30Link.click();
            await page.waitForLoadState('networkidle');
            await page.waitForTimeout(1500); // Wait for chart to re-render

            await page.screenshot({
              path: '#{output_dir}/dashboard-30days.png',
              fullPage: true
            });
            console.log('Saved: dashboard-30days.png');
          }

          console.log('Screenshots completed successfully!');
        } catch (e) {
          console.error('Error:', e.message);

          // Save error screenshot for debugging
          await page.screenshot({
            path: '#{output_dir}/dashboard-error.png',
            fullPage: true
          });
          console.log('Error screenshot saved: dashboard-error.png');
          process.exit(1);
        }

        await browser.close();
      })();
    JS
  end
end
