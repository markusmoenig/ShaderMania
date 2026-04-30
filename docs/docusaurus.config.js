// @ts-check

const config = {
  title: 'ShaderMania',
  tagline: 'Create, edit, and share Metal shaders on macOS and iPadOS.',
  favicon: 'img/logo_trans.png',

  url: 'https://shadermania.com',
  baseUrl: '/',

  organizationName: 'markusmoenig',
  projectName: 'ShaderMania',
  trailingSlash: false,

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en']
  },

  headTags: [
    {
      tagName: 'link',
      attributes: {
        rel: 'stylesheet',
        href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css'
      }
    }
  ],

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.js',
          routeBasePath: 'docs'
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css'
        }
      }
    ]
  ],

  themeConfig: {
    image: 'img/logo_trans.png',
    navbar: {
      title: 'ShaderMania',
      logo: {
        alt: 'ShaderMania logo',
        src: 'img/logo_trans.png'
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Docs'
        },
        {
          to: '/support',
          label: 'Support',
          position: 'left'
        },
        {
          href: 'https://apps.apple.com/us/app/shadermania/id1541065830',
          label: 'App Store',
          position: 'right'
        },
        {
          type: 'html',
          position: 'right',
          value: `
            <a href="https://discord.gg/BMStWPhByj" class="navbar-icon" title="ShaderMania Discord">
              <img src="https://img.shields.io/badge/Discord-Join%20Server-458588?style=flat&logo=discord" alt="Join Discord"/>
            </a>
          `
        },
        {
          type: 'html',
          position: 'right',
          value: `
            <a href="https://github.com/markusmoenig/ShaderMania" class="navbar-icon" title="GitHub Repository">
              <img src="https://img.shields.io/github/stars/markusmoenig/ShaderMania?style=flat&color=458588&logo=github" alt="GitHub stars"/>
            </a>
          `
        },
        {
          href: 'https://github.com/markusmoenig/ShaderMania',
          label: 'GitHub',
          position: 'right'
        }
      ]
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Social',
          items: [
            {
              label: 'Discord',
              to: 'https://discord.gg/BMStWPhByj'
            },
            {
              label: 'Bluesky',
              to: 'https://bsky.app/profile/markusmoenig.bsky.social'
            },
            {
              label: 'X',
              to: 'https://x.com/MarkusMoenig'
            }
          ]
        },
        {
          title: 'Legal',
          items: [
            {
              label: 'Support',
              to: '/support'
            },
            {
              label: 'Privacy Policy',
              to: '/privacy'
            }
          ]
        },
        {
          title: 'Links',
          items: [
            {
              label: 'Shader Format',
              to: '/docs/getting-started'
            },
            {
              label: 'App Store',
              to: 'https://apps.apple.com/us/app/shadermania/id1541065830'
            },
            {
              label: 'GitHub',
              to: 'https://github.com/markusmoenig/ShaderMania'
            }
          ]
        }
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Markus Moenig.`
    },
    prism: {
      additionalLanguages: ['swift']
    }
  }
};

export default config;
