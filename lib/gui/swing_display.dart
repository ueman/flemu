import 'package:gb_emulator/gpu/display.dart';
/*
class SwingDisplay implements Display {

    static const final  DISPLAY_WIDTH = 160;

    static const final  DISPLAY_HEIGHT = 144;

    final BufferedImage img;

    static const final COLORS = [0xe6f8da, 0x99c886, 0x437969, 0x051f2a];

    final List<int> _rgb;

    bool _enabled;

    int _scale;

     bool  _doStop;

    bool _doRefresh;

     int _i;

    SwingDisplay(this._scale) {
    
        GraphicsConfiguration gfxConfig = GraphicsEnvironment.
                getLocalGraphicsEnvironment().getDefaultScreenDevice().
                getDefaultConfiguration();
        img = gfxConfig.createCompatibleImage(DISPLAY_WIDTH, DISPLAY_HEIGHT);
        rgb = new int[DISPLAY_WIDTH * DISPLAY_HEIGHT];
        this.scale = scale;
    }

    @Override
    public void putDmgPixel(int color) {
        rgb[i++] = COLORS[color];
        i = i % rgb.length;
    }

    @Override
    public void putColorPixel(int gbcRgb) {
        rgb[i++] = translateGbcRgb(gbcRgb);
    }

    public static int translateGbcRgb(int gbcRgb) {
        int r = (gbcRgb >> 0) & 0x1f;
        int g = (gbcRgb >> 5) & 0x1f;
        int b = (gbcRgb >> 10) & 0x1f;
        int result = (r * 8) << 16;
        result |= (g * 8) << 8;
        result |= (b * 8) << 0;
        return result;
    }

    @Override
    public synchronized void requestRefresh() {
        doRefresh = true;
        notifyAll();
    }

    @Override
    public synchronized void waitForRefresh() {
        while (doRefresh) {
            try {
                wait(1);
            } catch (InterruptedException e) {
                break;
            }
        }
    }

    @Override
    public void enableLcd() {
        enabled = true;
    }

    @Override
    public void disableLcd() {
        enabled = false;
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);

        Graphics2D g2d = (Graphics2D) g.create();
        if (enabled) {
            g2d.drawImage(img, 0, 0, DISPLAY_WIDTH * scale, DISPLAY_HEIGHT * scale, null);
        } else {
            g2d.setColor(new Color(COLORS[0]));
            g2d.drawRect(0, 0, DISPLAY_WIDTH * scale, DISPLAY_HEIGHT * scale);
        }
        g2d.dispose();
    }

    @Override
    public void run() {
        doStop = false;
        doRefresh = false;
        enabled = true;
        while (!doStop) {
            synchronized (this) {
                try {
                    wait(1);
                } catch (InterruptedException e) {
                    break;
                }
            }

            if (doRefresh) {
                img.setRGB(0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT, rgb, 0, DISPLAY_WIDTH);
                validate();
                repaint();

                synchronized (this) {
                    i = 0;
                    doRefresh = false;
                    notifyAll();
                }
            }
        }
    }

    void stop() {
        _doStop = true;
    }
}
*/