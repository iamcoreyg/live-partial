import consumer from "./consumer"

class LivePartial {
  constructor(element) {
    this.element = element;
    this.eventHandlers = {};

    this.state = new Proxy(
      JSON.parse(element.dataset.state || '{}'),
      {
        set: (obj, prop, value) => {
          const oldValue = obj[prop];
          obj[prop] = value;
          this.emit('stateChange', { prop, value, oldValue });
          this.handleStateChange();
          return true;
        }
      }
    );

    this.setupWebSocket();
    this.emit('initialized');
  }

  on(eventName, handler) {
    this.eventHandlers[eventName] = this.eventHandlers[eventName] || [];
    this.eventHandlers[eventName].push(handler);
    return () => this.off(eventName, handler);
  }

  off(eventName, handler) {
    if (!this.eventHandlers[eventName]) return;
    this.eventHandlers[eventName] = this.eventHandlers[eventName].filter(h => h !== handler);
  }

  emit(eventName, data = {}) {
    if (!this.eventHandlers[eventName]) return;

    const eventData = {
      ...data,
      partial: this,
      element: this.element,
      partialName: this.element.dataset.partialName,
      timestamp: new Date()
    };

    this.eventHandlers[eventName].forEach(handler => handler(eventData));

    this.element.dispatchEvent(new CustomEvent(`live-partial:${eventName}`, {
      detail: eventData,
      bubbles: true
    }));
  }

  handleStateChange() {
    if (this.updateTimeout) clearTimeout(this.updateTimeout);
    this.emit('beforeDebounce', { state: this.state });

    this.updateTimeout = setTimeout(() => {
      this.sendUpdate();
    }, 100);
  }

  async sendUpdate() {
    try {
      this.emit('beforeUpdate', { state: this.state });

      const url = this.element.dataset.url;
      const method = this.element.dataset.httpMethod || 'POST';

      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          ...this.state,
          _live_partial_name: this.element.dataset.partialName,
          _live_partial_id: this.element.id,
          _resource_type: this.element.dataset.resourceType,
          _resource_id: this.element.dataset.resourceId
        })
      });

      const html = await response.text();

      this.emit('beforeRender', { html, response });
      this.element.innerHTML = html;
      this.emit('afterRender', { html, response });
    } catch (error) {
      this.emit('error', { error });
    }
  }

  setupWebSocket() {
    this.channel = consumer.subscriptions.create({
      channel: "LivePartial::UpdatesChannel",
      partial_id: this.element.id
    }, {
      received: (data) => {
        this.emit('beforeWebsocketRender', { data });
        this.element.innerHTML = data.html;
        this.emit('afterWebsocketRender', { data });
      }
    });
  }
}

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-live-partial]').forEach(element => {
    element.__livePartial = new LivePartial(element);
  });

  window.livePartial = (id) => {
    const el = document.querySelector(`[data-live-partial][id="${id}"]`);
    return el?.__livePartial;
  };
});

export default LivePartial;
