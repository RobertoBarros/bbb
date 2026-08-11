import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.refreshTimeout = setTimeout(() => this.refresh(), 5000)
  }

  disconnect() {
    clearTimeout(this.refreshTimeout)
    clearTimeout(this.reloadTimeout)
  }

  refresh() {
    this.statusTarget.hidden = false
    this.reloadTimeout = setTimeout(() => window.location.reload(), 300)
  }
}
