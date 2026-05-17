import useBaseUrl from '@docusaurus/useBaseUrl';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import styles from './index.module.css';

export default function Home() {
  const logoSrc = useBaseUrl('/img/logo_trans.png');

  return (
    <Layout
      title="ShaderMania"
      description="Create, edit, render, and share Metal shaders on macOS and iPadOS.">
      <main>
        <section className={styles.intro}>
          <div className={styles.introText}>
            <h1>Metal Shader Creation</h1>
            <p>
              ShaderMania is a family of creative Metal shader tools, from fast
              fragment shader sketching to timeline-based path-traced scene building
              with procedural SDFs, materials, images, and post effects.
            </p>
          </div>
          <img className={styles.logo} src={logoSrc} alt="ShaderMania logo" />
        </section>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
