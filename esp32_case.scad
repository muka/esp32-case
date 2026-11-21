// ESP32 DevKit (30-pin, USB-C, ESP-WROOM-32) enclosure
// Base + snap-fit lid with flexible BOOT / EN buttons and LED window.
//
// Render one part at a time:  part = "base" | "lid" | "both" (preview)
// Board dimensions were estimated from photos: MEASURE YOUR BOARD WITH CALIPERS
// and adjust pcb_l / pcb_w / button positions before printing.

part = "both";

/* [Board] */
pcb_l   = 55.0;   // along USB axis (antenna end -> USB end)
pcb_w   = 29.0;   // across the two header rows
pcb_t   = 1.6;
under   = 10.0;   // free space below PCB for soldered header pins
over    = 6.0;    // free space above PCB top (module ~3.2, USB-C ~3.3)
fit     = 0.6;    // gap between PCB edge and inner wall
usb_overhang = 1.0; // how far the USB-C receptacle sticks out past the PCB edge

// Feature positions in PCB coordinates (origin = antenna-end corner on the EN side,
// x toward USB, y toward the 3V3/BOOT header row, board top side up).
boot_pos = [51.0, 23.0];
en_pos   = [51.0,  6.0];
led_pos  = [31.0,  9.5];
usb_z    = 1.6;          // USB-C centre height above PCB top
btn_h    = 2.0;          // tactile button top above PCB top

/* [Case] */
wall    = 2.0;
floor_t = 2.0;
lid_t   = 2.0;
r_out   = 3.0;
lip_h   = 3.0;
lip_t   = 1.2;
lip_gap = 0.2;

usb_cut   = [12.5, 7.0];  // cable overmould opening (w, h)
wire_slot = true;         // slot on antenna end, below the PCB, for jumper wires
slot_wh   = [16, 6];
vents     = true;

$fn = 48;

// ---------------------------------------------------------------- derived
in_l  = pcb_l + usb_overhang + 2*fit;
in_w  = pcb_w + 2*fit;
out_l = in_l + 2*wall;
out_w = in_w + 2*wall;
z_pcb = floor_t + under;          // PCB bottom
z_top = z_pcb + pcb_t;            // PCB top
z_rim = z_top + over;             // top of base walls = lid underside
eps   = 0.01;

// PCB coordinate -> case coordinate
function P(p) = [wall + fit + p[0], wall + fit + p[1]];

module rbox(l, w, h, r) {
    hull() for (x = [r, l - r], y = [r, w - r])
        translate([x, y, 0]) cylinder(r = r, h = h);
}

module usb_hole(extra = 0) {
    c = P([pcb_l, pcb_w/2]);
    translate([out_l - wall - 1, c[1], z_top + usb_z])
        rotate([0, 90, 0])
            hull() for (s = [-1, 1])
                translate([0, s*(usb_cut[0] - usb_cut[1])/2, 0])
                    cylinder(d = usb_cut[1] + extra, h = wall + 2 + extra);
}

// ---------------------------------------------------------------- base
module base() {
    difference() {
        rbox(out_l, out_w, z_rim, r_out);
        // cavity
        translate([wall, wall, floor_t]) rbox(in_l, in_w, z_rim, max(r_out - wall, 0.5));
        usb_hole();
        if (wire_slot)
            translate([-1, out_w/2 - slot_wh[0]/2, floor_t + 1.5])
                cube([wall + 2, slot_wh[0], slot_wh[1]]);
        // snap grooves on long walls
        for (y = [wall - 0.5, out_w - wall - eps])
            translate([out_l/2 - 8, y, z_rim - lip_h/2 - 0.6])
                cube([16, 0.5 + eps, 1.2]);
    }
    // corner support pads (avoid header pins, which start ~5.5 mm from each end)
    pad = [4.0, 5.0];
    for (x = [0, pcb_l - pad[0]], y = [0, pcb_w - pad[1]]) {
        p = P([x, y]);
        translate([p[0] - (x == 0 ? fit : 0), p[1] - (y == 0 ? fit : 0), floor_t - eps])
            cube([pad[0] + fit + (x == 0 ? 0 : usb_overhang), pad[1] + fit, under + eps]);
    }
}

// ---------------------------------------------------------------- lid
// Modelled in place (lid underside at z_rim). Printed flipped (see lid_print()).
tab_w = 4.0; tab_l = 10.0; tab_t = 1.0; slit = 0.8;

module flex_tab_cut(p) {
    c = P(p);
    // U-shaped slit, hinge toward the centre of the board (-x)
    translate([c[0] - tab_l + tab_w/2, c[1], z_rim - eps])
        difference() {
            translate([0, -tab_w/2 - slit, 0])
                cube([tab_l + slit, tab_w + 2*slit, lid_t + 2*eps]);
            translate([-eps, -tab_w/2, -eps])
                cube([tab_l, tab_w, lid_t + 4*eps]);
        }
    // thin the tab from below so it flexes
    translate([c[0] - tab_l + tab_w/2, c[1] - tab_w/2, z_rim - eps])
        cube([tab_l, tab_w, lid_t - tab_t + eps]);
}

module flex_tab_nub(p) {
    c = P(p);
    z0 = z_top + btn_h + 0.3;
    translate([c[0], c[1], z0]) cylinder(d = 3, h = z_rim + lid_t - tab_t - z0 + eps);
}

module lid() {
    difference() {
        union() {
            translate([0, 0, z_rim]) rbox(out_l, out_w, lid_t, r_out);
            // locating lip
            difference() {
                translate([wall + lip_gap, wall + lip_gap, z_rim - lip_h])
                    rbox(in_l - 2*lip_gap, in_w - 2*lip_gap, lip_h + eps, max(r_out - wall - lip_gap, 0.5));
                translate([wall + lip_gap + lip_t, wall + lip_gap + lip_t, z_rim - lip_h - 1])
                    cube([in_l - 2*(lip_gap + lip_t), in_w - 2*(lip_gap + lip_t), lip_h + 2]);
            }
            // snap bumps
            for (y = [wall + lip_gap, out_w - wall - lip_gap])
                translate([out_l/2 - 7, y, z_rim - lip_h/2 - 0.6 + 0.6])
                    rotate([0, 90, 0]) cylinder(r = 0.45, h = 14, $fn = 16);
            // hold-down blocks on the PCB corners (sized to bridge the mounting holes,
            // kept clear of the module, header pins, buttons and USB-C)
            for (b = [[0, 0, 2.0, 4.5], [0, pcb_w - 4.5, 2.0, 4.5],
                      [pcb_l - 1.5, 0.3, 1.5, 2.7], [pcb_l - 1.5, pcb_w - 3.0, 1.5, 2.7]]) {
                c = P([b[0], b[1]]);
                translate([c[0], c[1], z_top + 0.1]) cube([b[2], b[3], over]);
            }
        }
        // clear lip around the USB connector
        translate([out_l - wall - lip_t - 2, out_w/2 - usb_cut[0]/2 - 1, z_rim - lip_h - 1])
            cube([lip_t + 3, usb_cut[0] + 2, lip_h + 1]);
        flex_tab_cut(boot_pos);
        flex_tab_cut(en_pos);
        // LED window
        c = P(led_pos);
        translate([c[0], c[1], z_rim - 1]) cylinder(d = 4, h = lid_t + 2);
        // vents over the middle of the board
        if (vents)
            for (i = [0:4])
                translate([P([8 + i*3.2, 0])[0], P([0, 13])[1] - 5, z_rim - 1])
                    hull() {
                        cylinder(d = 1.6, h = lid_t + 2, $fn = 16);
                        translate([0, 10, 0]) cylinder(d = 1.6, h = lid_t + 2, $fn = 16);
                    }
    }
    flex_tab_nub(boot_pos);
    flex_tab_nub(en_pos);
}

module lid_print() {
    translate([0, out_w, z_rim + lid_t]) rotate([180, 0, 0]) lid();
}

// ---------------------------------------------------------------- dummy board (preview only)
module board() {
    color("darkgreen") translate([P([0, 0])[0], P([0, 0])[1], z_pcb]) cube([pcb_l, pcb_w, pcb_t]);
    color("silver") translate([P([0, 5])[0], P([0, 5])[1], z_top]) cube([25, 19, 3.2]);
    color("silver") translate([P([pcb_l - 7, pcb_w/2 - 4.5])[0], P([0, pcb_w/2 - 4.5])[1], z_top]) cube([8, 9, 3.2]);
    for (y = [1.3, pcb_w - 1.3], i = [0:14])
        color("black") translate([P([5.6 + i*2.54, y])[0] - 1.27, P([0, y])[1] - 1.27, z_pcb - 2.5]) cube([2.54, 2.54, 2.5]);
}

if (part == "base") base();
else if (part == "lid") lid_print();
else { base(); board(); translate([0, 0, 15]) %lid(); }
