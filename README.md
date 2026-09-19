# HATSUNE MIKU ON FPGA TINYTAPEOUT

## How it works

This chip creates a live picture on a computer monitor without needing a computer brain, memory card, or software. Everything you see is drawn instantly by the physical wiring inside the chip.

* **Tracking the Screen:** The chip counts every single dot and line from top to bottom, 60 times every second, to keep the picture perfectly in place.
* **Drawing the Picture:** As the screen draws each dot, the chip chooses the color based on where the dot is. It uses Hatsune Miku's signature colors—bright teal, black, and pink accents—to form the image.
* **Screen Timing:** The chip tells the monitor when to jump to the next line and when to restart at the top of the screen so the picture stays steady and clear.
* **Color Output:** It sends the final colors directly to the display board as red, green, and blue signals.

## How to test

### 1. Test in a Web Browser

You can see what the chip draws right on your computer without any physical parts:

* Open `[https://vga-playground.com/?repo=https://github.com/](https://vga-playground.com/?repo=https://github.com/)<your-username>/<your-repo-name>`
* The page runs the chip design in your browser and shows the live picture immediately.

### 2. Run the Automatic Tests

Run the included test script on your computer to make sure the signals turn on and off properly:

```bash
cd test
make

```

### 3. Test on Real Hardware

1. Plug the TinyVGA display adapter board into the chip board output pins.
2. Connect a monitor cable from the adapter board to a standard monitor.
3. Turn on the chip's speed clock.
4. Press and release the reset button to start the picture from the top left corner.
5. Flip the selector switches to turn this project on, and the image will appear on your screen.

## External hardware

* **TinyVGA adapter board:** Plugs into the chip pins so a monitor cable can connect to it.
* **Standard monitor:** Any regular computer screen with a blue VGA plug.
* **VGA monitor cable:** Connects the adapter board to the screen.
* **Clock source:** Provides the steady pulse that sets the chip's drawing speed.
