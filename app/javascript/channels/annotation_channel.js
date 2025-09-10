import consumer from "./consumer"

function annotation_channel_connect(ldc){
  let channel;
  let o = {};
  o.channel = "AnnotationChannel";
  o.kit_uid = ldc.obj2._id;
  o.xlass_def_id = ldc.obj2.xlass_def_id;
  o.task_user_id = ldc.obj2.task_user_id;
  consumer.subscriptions.create(o, {
    // Called once when the subscription is created.
    initialized() {
      // this.update = this.update.bind(this)
      channel = this;
      ldc.annotate = (x) => {
        const d = new Date();
        x.client_time = d.getTime();
        channel.perform("annotate", x)
      };
    },

    // Called when the subscription is ready for use on the server.
    connected() {
          console.log("Annotation Channel connection active");
      // this.install()
      // this.update()
    },

    // Called when the WebSocket connection is closed.
    disconnected() {
      // this.uninstall()
    },

    received(data) {
          console.log("Received data", data);
          ldc.annotate_received(data);
      // new Notification(data["title"], { body: data["body"] })
    },

    // Called when the subscription is rejected by the server.
    rejected() {
      // this.uninstall()
    },

    update() {
      // this.documentIsActive ? this.appear() : this.away()
    },

    appear() {
      // Calls `AppearanceChannel#appear(data)` on the server.
      // this.perform("appear", { appearing_on: this.appearingOn })
    },

    away() {
      // Calls `AppearanceChannel#away` on the server.
      // this.perform("away")
    },

    install() {
      // window.addEventListener("focus", this.update)
      // window.addEventListener("blur", this.update)
      // document.addEventListener("turbo:load", this.update)
      // document.addEventListener("visibilitychange", this.update)
    },

    uninstall() {
      // window.removeEventListener("focus", this.update)
      // window.removeEventListener("blur", this.update)
      // document.removeEventListener("turbo:load", this.update)
      // document.removeEventListener("visibilitychange", this.update)
    },

    get documentIsActive() {
      return document.visibilityState === "visible" && document.hasFocus()
    },

    get appearingOn() {
      const element = document.querySelector("[data-appearing-on]")
      return element ? element.getAttribute("data-appearing-on") : null
    }

  })
}

export { annotation_channel_connect }