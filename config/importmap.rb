# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application'
pin '@hotwired/turbo-rails', to: 'turbo.min.js'
pin '@hotwired/stimulus', to: 'stimulus.min.js'
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js'
pin_all_from 'app/javascript/controllers', under: 'controllers'
# Chart.js - используем ESM bundle с CDN (self-contained)
pin 'chart.js/auto', to: 'https://cdn.jsdelivr.net/npm/chart.js@4.4.7/auto/+esm'
