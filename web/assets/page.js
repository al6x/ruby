let p = console.log.bind(console)

export class Page {
  constructor() {
    this.log = Log("page")
    this._listen_to_dom_events()
    this._connect()
  }

  _listen_to_dom_events() {
    let self = this
    async function handle(raw_event) {
      const event = { keys: [] }
      if (raw_event.altKey) event.keys.push("alt")
      if (raw_event.ctrlKey) event.keys.push("ctrl")
      if (raw_event.shiftKey) event.keys.push("shift")
      if (raw_event.metaKey) event.keys.push("meta")
      let target = raw_event.srcElement
      while (target && target != document.body) {
        if (target.id != "") {
          event.id = target.id
          break
        }

        target = target.parentElement
      }
      if (!event.id) throw new Error("can't get id for event")
      try   { self.send({ click: event }) }
      catch { self.log.error("can't send event") }
    }
    document.body.addEventListener("click", handle)
  }

  send(event) {
    if (!this.socket) {
      this.log.error('socket closed')
      return
    }
    this.log.info('>>', event)
    this.socket.send(JSON.stringify(event))
  }

  handle(event) {
    this.log.info('<<', event)
    if ('eval' in event) {
      this.log.info("eval", { code: event.eval })
      eval("'use strict'; " + event.eval)
    } else {
      this.log.error("unknown event", { event: event })
    }
  }

  _connect() {
    this.socket = new WebSocket('ws://' + location.hostname + ':' + location.port + '/', ['xmpp'])

    this.socket.addEventListener('open', () => this.log.info('socket opened'))

    this.socket.onerror = (event) => {
      this.log.error('socket error', { error: event.message })
    }

    this.socket.onclose = (event) => {
      this.log.info('socket closed')
      this.socket = null
    }

    this.socket.onmessage = (event) => {
      this.handle(JSON.parse(event.data))
    }
  }
}

const http_log = Log("http", false)
function send(method, url, data = {}, timeout = 5000) {
  http_log.info("send", { method, url, data })
  return new Promise((resolve, reject) => {
    var responded = false
    var xhr = new XMLHttpRequest()
    xhr.open(method.toUpperCase(), url, true)
    xhr.onreadystatechange = function(){
      if(responded) return
      if(xhr.readyState == 4){
        responded = true
        if(xhr.status == 200) {
          const response = JSON.parse(xhr.responseText)
          http_log.info("http receive", { method, url, data, response })
          resolve(response)
        } else {
          const error = new Error(xhr.responseText)
          http_log.info("http error", { method, url, data, error })
          reject(error)
        }
      }
    }
    if (timeout > 0) {
      setTimeout(function(){
        if(responded) return
        responded = true
        const error = new Error("no response from " + url + "!")
        http_log.info("http error", { method, url, data, error })
        reject(error)
      }, timeout)
    }
    xhr.send(JSON.stringify(data))
  })
}

function sleep(ms) {
  return new Promise((resolve, reject) => {
    setTimeout(() => { resolve() }, ms)
  })
}

function Log(component) {
  if (Log.disabled) return {
    info(msg, data = {})  {},
    error(msg, data = {}) {},
    warn(msg, data = {})  {}
  }

  component = component.substring(0, 4).padEnd(4)
  function skip_empty_data(message, data) {
    return Object.keys(data).length > 0 ? [message, data] : [message]
  }
  return {
    info(msg, data = {})  { console.log(...skip_empty_data("  " + component + " | " + msg, data)) },
    error(msg, data = {}) { console.log(...skip_empty_data("E " + component + " | " + msg, data)) },
    warn(msg, data = {})  { console.log(...skip_empty_data("W " + component + " | " + msg, data)) }
  }
}