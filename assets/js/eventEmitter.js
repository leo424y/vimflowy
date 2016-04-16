// From: https://gist.github.com/contra/2759355

class EventEmitter {
  constructor() {
    // mapping from event to list of listeners
    this.listeners = {}
    this.hooks = {}
  }

  // emit an event and return all responses from the listeners
  emit(event, ...args) {
    ((listener event, args...) for listener in (this.listeners['all'] or []))
    return ((listener args...) for listener in (this.listeners[event] or []))
  }

  addListener(event, listener) {
    this.emit 'newListener', event, listener
    (this.listeners[event]?=[]).push listener
    return this;
  }

  addListenerForAll(listener) {
    this.addListener 'all', listener
  }

  on: this.addListener
  onAll: this.addListenerForAll

  once(event, listener) {
    fn = =>
      this.removeListener event, fn
      listener arguments...
    this.on event, fn
    return this
  }

  removeListener(event, listener) {
    if (!this.listeners[event]) {
      return this;
    }
    this.listeners[event] = this.listeners[event].filter((l) => {
      l !== listener
    })
    return this;
  }

  removeAllListeners(event) {
    delete this.listeners[event]
    return this;
  }

  // hooks for mutating
  // NOTE: a little weird for eventEmitter to be in charge of this

  addHook(event, transform) {
    (this.hooks[event]?=[]).push transform
  }

  applyHook(event, obj, info) {
    for transform in (this.hooks[event] or [])
      obj = transform obj, info
    return obj
  }
}

// exports
module?.exports = EventEmitter
window?.EventEmitter = EventEmitter
