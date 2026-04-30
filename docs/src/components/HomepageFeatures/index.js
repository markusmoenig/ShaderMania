import FeaturesContent from "./FeaturesContent.mdx";
import styles from "./styles.module.css";

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className={styles.featuresInner}>
        <FeaturesContent />
      </div>
    </section>
  );
}
