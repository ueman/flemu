import 'package:gb_emulator/cpu/speed_mode.dart';
import 'package:gb_emulator/gameboy.dart';
import 'package:gb_emulator/gameboy_options.dart';
import 'package:gb_emulator/memory/cart/cartridge.dart';
import 'package:gb_emulator/serial/serial_endpoint.dart';
/*
class Emulator {

    static const int SCALE = 2;

     final GameboyOptions _options;

     final Cartridge _rom;

     final AudioSystemSoundOutput _sound;

     final SwingDisplay _display;

     final SwingController _controller;

     final SerialEndpoint _serialEndpoint;

     final SpeedMode _speedMode;

     final Gameboy _gameboy;

     JFrame mainWindow;

     Emulator(List<String> args, Properties properties)  {
        options = parseArgs(args);
        rom = new Cartridge(options);
        speedMode = new SpeedMode();
        serialEndpoint = SerialEndpoint.NULL_ENDPOINT;
        console = options.isDebug() ? Optional.of(new Console()) : Optional.empty();
        console.map(Thread::new).ifPresent(Thread::start);

        if (options.isHeadless()) {
            sound = null;
            display = null;
            controller = null;
            gameboy = new Gameboy(options, rom, Display.NULL_DISPLAY, Controller.NULL_CONTROLLER, SoundOutput.NULL_OUTPUT, serialEndpoint, console);
        } else {
            sound = new AudioSystemSoundOutput();
            display = new SwingDisplay(SCALE);
            controller = new SwingController(properties);
            gameboy = new Gameboy(options, rom, display, controller, sound, serialEndpoint, console);
        }
        console.ifPresent(c -> c.init(gameboy));
    }

    static GameboyOptions parseArgs(String[] args) {
        if (args.length == 0) {
            GameboyOptions.printUsage(System.out);
            System.exit(0);
            return null;
        }
        try {
            return createGameboyOptions(args);
        } catch(IllegalArgumentException e) {
            System.err.println(e.getMessage());
            System.err.println();
            GameboyOptions.printUsage(System.err);
            System.exit(1);
            return null;
        }
    }

    static GameboyOptions createGameboyOptions(String[] args) {
        Set<String> params = new HashSet<>();
        Set<String> shortParams = new HashSet<>();
        String romPath = null;
        for (String a : args) {
            if (a.startsWith("--")) {
                params.add(a.substring(2));
            } else if (a.startsWith("-")) {
                shortParams.add(a.substring(1));
            } else {
                romPath = a;
            }
        }
        if (romPath == null) {
            throw new IllegalArgumentException("ROM path hasn't been specified");
        }
        File romFile = new File(romPath);
        if (!romFile.exists()) {
            throw new IllegalArgumentException("The ROM path doesn't exist: " + romPath);
        }
        return new GameboyOptions(romFile, params, shortParams);
    }

     void run() throws Exception {
        if (options.isHeadless()) {
            gameboy.run();
        } else {
            System.setProperty("sun.java2d.opengl", "true");

            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            SwingUtilities.invokeLater(() -> startGui());
        }
    }

    private void startGui() {
        display.setPreferredSize(new Dimension(160 * SCALE, 144 * SCALE));

        mainWindow = new JFrame("Coffee GB: " + rom.getTitle());
        mainWindow.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        mainWindow.setLocationRelativeTo(null);

        mainWindow.setContentPane(display);
        mainWindow.setResizable(false);
        mainWindow.setVisible(true);
        mainWindow.pack();

        mainWindow.addKeyListener(controller);

        new Thread(display).start();
        new Thread(gameboy).start();
    }

    private void stopGui() {
        display.stop();
        gameboy.stop();
        mainWindow.dispose();
    }
}
*/