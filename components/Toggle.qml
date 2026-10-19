import QtQuick
import "../services"

// Setting row bound to a boolean in Config.opts.
Setting {
    id: tg
    property string key
    Switch { checked: Config.opts[tg.key]; onToggled: v => Config.opts[tg.key] = v }
}
