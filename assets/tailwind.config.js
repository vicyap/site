// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/my_site_web.ex",
    "../lib/my_site_web/**/*.*ex",
  ],
  safelist: ["dark"],
  darkMode: "class",
  theme: {
    fontFamily: {
      body: ["Poppins", "sans-serif"],
    },

    screens: {
      xs: "375px",
      ...defaultTheme.screens,
    },

    colors: {
      transparent: "transparent",
      primary: "#072344",
      secondary: "#00aaa1",
      "green-light": "#cceeec",
      green: "#007c85",
      "green-dark": "#065a68",
      "blue-light": "#b3d6f1",
      blue: "#0074d1",
      "blue-dark": "#072344",
      black: "#000000",
      white: "#ffffff",
      "yellow-lighter": "#f6e8c6",
      "yellow-light": "#f8edd0",
      yellow: "#f4d06f",
      "yellow-dark": "#daa512",
      "grey-lightest": "#eff0f3",
      "grey-lighter": "#eceef1",
      "grey-light": "#ccd7e0",
      grey: "#adb6c4",
    },

    border: {
      DEFAULT: "1px",
      0: "0",
      2: "2px",
      4: "4px",
      6: "6px",
      8: "8px",
    },

    container: {
      center: true,
      padding: "1rem",
    },

    extend: {
      colors: {
        brand: "#FD4F00",
      },
      spacing: {
        13: "3.25rem",
        15: "3.75rem",
        17: "4.25rem",
        18: "4.5rem",
        19: "4.75rem",
        76: "19rem",
        84: "21rem",
        88: "22rem",
        92: "23rem",
        100: "25rem",
        104: "26rem",
        108: "27rem",
        112: "28rem",
        116: "29rem",
        120: "30rem",
        124: "31rem",
        128: "32rem",
        132: "33rem",
        136: "34rem",
        140: "35rem",
        144: "36rem",
        148: "37rem",
        152: "38rem",
        156: "39rem",
        160: "40rem",
        164: "41rem",
        168: "42rem",
        172: "43rem",
        176: "44rem",
        180: "45rem",
        184: "46rem",
        188: "47rem",
        190: "48rem",
        194: "49rem",
        200: "50rem",
        204: "51rem",
      },
      inset: {
        50: "50%",
        100: "100%",
      },
      zIndex: {
        "-1": "-1",
      },
      typography: (theme) => ({
        DEFAULT: {
          css: {
            color: theme("colors.primary"),
            a: {
              fontWeight: theme("fontWeight.semibold"),
              color: theme("colors.green"),
              textDecoration: "underline",
              transition: "color 300ms",
              "&:hover": {
                color: theme("colors.primary"),
              },
            },
            "p, li": {
              fontWeight: theme("fontWeight.light"),
            },
            "h1, h2, h3, h4, h5, h6": {
              fontWeight: theme("fontWeight.semibold"),
            },
            "ul > li::before": {
              backgroundColor: theme("colors.primary"),
            },
            blockquote: {
              borderLeftWidth: "1rem",
              borderColor: theme("colors.green-dark"),
              borderRadius: "3px",
              backgroundColor: theme("colors.green-light"),
              padding: `${theme("spacing.4")} ${theme("spacing.6")}`,
              color: theme("colors.green"),
              fontStyle: "normal",
              p: {
                margin: 0,
                fontWeight: theme("fontWeight.normal"),
              },
            },
          },
        },
        dark: {
          css: {
            color: theme("colors.white"),
            a: {
              color: theme("colors.secondary"),
              "&:hover": {
                color: theme("colors.green"),
              },
            },
            "h1, h2, h3, h4, h5, h6": {
              color: theme("colors.white"),
            },
            "ul > li::before": {
              backgroundColor: theme("colors.secondary"),
            },
          },
        },
      }),
    },
  },
  plugins: [
    require("@tailwindcss/typography")({
      modifiers: [],
    }),
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            let size = theme("spacing.6");
            if (name.endsWith("-mini")) {
              size = theme("spacing.5");
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4");
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: size,
              height: size,
            };
          },
        },
        { values }
      );
    }),
  ],
};
