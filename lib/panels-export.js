// Run inside plasmashell (org.kde.PlasmaShell.evaluateScript) by `plasmonk panels save`.
// Prints a Plasma layout script that recreates every panel: its geometry, its widgets in
// order, and each widget's settings. Dialog sizes (ConfigDialog groups) are left out.

// configGroups/configKeys are live views that change with currentConfigGroup: copy them.
function copy(seq) { return JSON.parse(JSON.stringify(seq)); }

// Returns [[groupPath, {key: value}], ...] for obj's config, recursing into subgroups.
// skipTop lists top-level groups to leave out; rootKeys = false also leaves out top-level keys.
function dumpConfig(obj, path, skipTop, rootKeys, out) {
    obj.currentConfigGroup = path;
    var keys = copy(obj.configKeys), groups = copy(obj.configGroups), values = {}, n = 0;
    for (var i = 0; i < keys.length; i++) {
        values[keys[i]] = obj.readConfig(keys[i]);
        n++;
    }
    if (n > 0 && (rootKeys || path.length > 0)) out.push([path, values]);
    for (var j = 0; j < groups.length; j++) {
        if (groups[j] === "ConfigDialog") continue;
        if (path.length === 0 && skipTop.indexOf(groups[j]) >= 0) continue;
        dumpConfig(obj, path.concat([groups[j]]), skipTop, rootKeys, out);
    }
    return out;
}

var lines = [];
function emit(s) { lines.push(s); }

emit("// Plasmonk panel layout, saved by `plasmonk panels save` on " + new Date().toISOString() + ".");
emit("// `plasmonk panels restore` runs this inside plasmashell. It REPLACES all current panels.");
emit("var missing = [];");
emit("function widget(panel, type, config) {");
emit("    var w = panel.addWidget(type);");
emit("    if (!w) { missing.push(type); return; }");
emit("    for (var i = 0; i < config.length; i++) {");
emit("        w.currentConfigGroup = config[i][0];");
emit("        for (var k in config[i][1]) w.writeConfig(k, config[i][1][k]);");
emit("    }");
emit("    w.reloadConfig();");
emit("}");
emit("var old = panels();");
emit("for (var i = old.length - 1; i >= 0; i--) old[i].remove();");

var ps = panels();
for (var i = 0; i < ps.length; i++) {
    var p = ps[i];
    emit("");
    emit("var p = new Panel(" + JSON.stringify(p.type) + ");");
    emit("p.location = " + JSON.stringify(p.location) + ";");
    var props = ["height", "alignment", "lengthMode", "hiding", "floating", "floatingApplets", "opacity"];
    if (p.lengthMode === "custom") props = props.concat(["offset", "minimumLength", "maximumLength"]);
    for (var j = 0; j < props.length; j++) {
        if (p[props[j]] !== undefined) emit("p." + props[j] + " = " + JSON.stringify(p[props[j]]) + ";");
    }

    // Widgets in their on-screen order (AppletOrder), then any the order does not list.
    var byId = {}, ws = p.widgets(), ordered = [];
    for (var j = 0; j < ws.length; j++) byId[ws[j].id] = ws[j];
    p.currentConfigGroup = ["General"];
    var order = String(p.readConfig("AppletOrder") || "").split(";");
    for (var j = 0; j < order.length; j++) {
        if (byId[order[j]]) { ordered.push(byId[order[j]]); delete byId[order[j]]; }
    }
    for (var id in byId) ordered.push(byId[id]);

    for (var j = 0; j < ordered.length; j++) {
        var w = ordered[j];
        // The system tray widget exposes its inner containment: keep only its General group
        // (shown/hidden items); the tray recreates its item applets from that.
        var tray = w.type === "org.kde.plasma.systemtray";
        emit("widget(p, " + JSON.stringify(w.type) + ", " + JSON.stringify(dumpConfig(w, [], tray ? ["Applets"] : [], !tray, [])) + ");");
    }
}
emit("");
emit("print(missing.length ? \"missing widgets: \" + missing.join(\" \") : \"ok\");");
print(lines.join("\n") + "\n");
