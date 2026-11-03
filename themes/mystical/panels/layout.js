// Plasmonk panel layout, saved by `plasmonk panels save` on 2026-11-02T23:18:53.255Z.
// `plasmonk panels restore` runs this inside plasmashell. It REPLACES all current panels.
var missing = [];
function widget(panel, type, config) {
    var w = panel.addWidget(type);
    if (!w) { missing.push(type); return; }
    for (var i = 0; i < config.length; i++) {
        w.currentConfigGroup = config[i][0];
        for (var k in config[i][1]) w.writeConfig(k, config[i][1][k]);
    }
    w.reloadConfig();
}
var old = panels();
for (var i = old.length - 1; i >= 0; i--) old[i].remove();

var p = new Panel("org.kde.panel");
p.location = "top";
p.height = 42;
p.alignment = "center";
p.lengthMode = "fill";
p.hiding = "none";
p.floating = true;
p.floatingApplets = false;
p.opacity = "translucent";
widget(p, "org.kde.plasma.kickoff", [[[],{"popupHeight":"511","popupWidth":"647"}],[["Shortcuts"],{"global":"Alt+F1"}],[["General"],{"compactMode":"true","favoritesDisplay":"1","favoritesPortedToKAstats":"true","icon":"org.cachyos.hello","systemFavorites":"suspend\\,hibernate\\,reboot\\,shutdown"}]]);
widget(p, "org.kde.plasma.pager", []);
widget(p, "org.kde.plasma.appmenu", []);
widget(p, "org.kde.plasma.panelspacer", []);
widget(p, "luisbocanegra.audio.visualizer", [[[],{"popupHeight":"451","popupWidth":"450"}],[["General"],{"barColors":"{\"alpha\":1,\"colorsOrientation\":0,\"custom\":\"#013eff\",\"enabled\":false,\"followColor\":0,\"hueEnd\":360,\"hueStart\":0,\"image\":{\"fillMode\":2,\"source\":\"\"},\"lightness\":0.5,\"lightnessEnabled\":false,\"list\":[\"#ED8796\",\"#A6DA95\",\"#EED49F\",\"#8AADF4\",\"#F5BDE6\",\"#8BD5CA\",\"#f5a97f\"],\"reverseList\":false,\"saturation\":0.5,\"saturationEnabled\":false,\"smoothGradient\":true,\"sourceType\":1,\"systemColor\":\"textColor\",\"systemColorSet\":\"Window\"}","drawInactiveBlocks":"true","inactiveBlockColors":"{\"alpha\":0.3,\"colorsOrientation\":0,\"custom\":\"#013eff\",\"enabled\":false,\"followColor\":0,\"hueEnd\":360,\"hueStart\":0,\"image\":{\"fillMode\":2,\"source\":\"\"},\"lightness\":0.5,\"lightnessEnabled\":false,\"list\":[\"#ED8796\",\"#A6DA95\",\"#EED49F\",\"#8AADF4\",\"#F5BDE6\",\"#8BD5CA\",\"#f5a97f\"],\"reverseList\":false,\"saturation\":0.5,\"saturationEnabled\":false,\"smoothGradient\":true,\"sourceType\":1,\"systemColor\":\"textColor\",\"systemColorSet\":\"Window\"}","length":"100","visualizerStyle":"2","waveFillColors":"{\"alpha\":0.3,\"colorsOrientation\":0,\"custom\":\"#013eff\",\"enabled\":false,\"followColor\":0,\"hueEnd\":360,\"hueStart\":0,\"image\":{\"fillMode\":2,\"source\":\"\"},\"lightness\":0.5,\"lightnessEnabled\":false,\"list\":[\"#ED8796\",\"#A6DA95\",\"#EED49F\",\"#8AADF4\",\"#F5BDE6\",\"#8BD5CA\",\"#f5a97f\"],\"reverseList\":false,\"saturation\":0.5,\"saturationEnabled\":false,\"smoothGradient\":true,\"sourceType\":7,\"systemColor\":\"highlightColor\",\"systemColorSet\":\"Window\"}"}]]);
widget(p, "org.kde.plasma.panelspacer", []);
widget(p, "org.kde.plasma.catwalk", [[[],{"CurrentPreset":"org.kde.plasma.systemmonitor","popupHeight":"400","popupWidth":"560"}],[["Sensors"],{"highPrioritySensorIds":"[\"cpu/all/usage\"]","lowPrioritySensorIds":"[\"cpu/all/cpuCount\",\"cpu/all/coreCount\"]","totalSensors":"[\"cpu/all/usage\"]"}],[["Appearance"],{"chartFace":"org.kde.ksysguard.piechart","title":"Total CPU Use"}],[["General"],{"type":"1"}],[["SensorColors"],{"cpu/all/usage":"105,74,75"}]]);
widget(p, "org.kde.plasma.marginsseparator", []);
widget(p, "org.kde.olib.thermalmonitor", [[[],{"popupHeight":"181","popupWidth":"288"}]]);
widget(p, "org.kde.plasma.systemtray", [[["General"],{"extraItems":"org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.brightness,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.keyboardlayout,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.networkmanagement,org.kde.plasma.notifications,org.kde.plasma.volume,org.kde.kdeconnect,org.kde.plasma.bluetooth,org.kde.plasma.keyboardindicator,org.kde.plasma.weather,org.kde.plasma.dwellclicker","knownItems":"org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.brightness,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.keyboardlayout,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.networkmanagement,org.kde.plasma.notifications,org.kde.plasma.volume,org.kde.kdeconnect,org.kde.plasma.bluetooth,org.kde.plasma.keyboardindicator,org.kde.plasma.weather,org.kde.plasma.dwellclicker"}]]);
widget(p, "org.kde.plasma.digitalclock", [[[],{"popupHeight":"451","popupWidth":"560"}]]);

var p = new Panel("org.kde.panel");
p.location = "bottom";
p.height = 38;
p.alignment = "center";
p.lengthMode = "fit";
p.hiding = "none";
p.floating = false;
p.floatingApplets = false;
p.opacity = "translucent";
widget(p, "org.kde.plasma.icontasks", []);

print(missing.length ? "missing widgets: " + missing.join(" ") : "ok");

