const fs = require('fs');
const path = require('path');
const { execSync, spawnSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const mode = (process.argv[2] || 'debug').toLowerCase();
const isWin = process.platform === 'win32';
const javaBinName = isWin ? 'java.exe' : 'java';
const gradlew = isWin ? '.\\gradlew.bat' : './gradlew';
const gradleTask = mode === 'release' ? 'bundleRelease' : 'assembleDebug';

function run(command, options = {}) {
  execSync(command, {
    cwd: root,
    stdio: 'inherit',
    env: options.env || process.env,
    shell: true
  });
}

function javaMajorFromHome(home) {
  if (!home) return null;
  const javaPath = path.join(home, 'bin', javaBinName);
  if (!fs.existsSync(javaPath)) return null;

  const result = spawnSync(javaPath, ['-version'], { encoding: 'utf8' });
  const output = [result.stdout, result.stderr].filter(Boolean).join('\n');
  const match = output.match(/version\s+"([^"]+)"/i) || output.match(/openjdk version\s+"([^"]+)"/i) || output.match(/java version\s+"([^"]+)"/i);
  if (!match) return null;

  const version = match[1];
  if (version.startsWith('1.')) {
    const major = parseInt(version.split('.')[1], 10);
    return Number.isFinite(major) ? major : null;
  }
  const major = parseInt(version.split('.')[0], 10);
  return Number.isFinite(major) ? major : null;
}

function addCandidate(list, home, seen) {
  if (!home || seen.has(home)) return;
  seen.add(home);
  list.push(home);
}

function addHomesFromBase(list, base, seen) {
  if (!base || !fs.existsSync(base)) return;
  const stat = fs.statSync(base);
  if (!stat.isDirectory()) return;

  const directJava = path.join(base, 'bin', javaBinName);
  if (fs.existsSync(directJava)) {
    addCandidate(list, base, seen);
    return;
  }

  for (const entry of fs.readdirSync(base)) {
    const full = path.join(base, entry);
    try {
      if (fs.statSync(full).isDirectory() && fs.existsSync(path.join(full, 'bin', javaBinName))) {
        addCandidate(list, full, seen);
      }
    } catch (_) {}
  }
}

function discoverJavaHomes() {
  const candidates = [];
  const seen = new Set();

  addCandidate(candidates, process.env.JAVA_HOME, seen);

  if (isWin) {
    addCandidate(candidates, 'C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.17.10-hotspot', seen);
    addCandidate(candidates, 'C:\\Program Files\\Microsoft\\jdk-17', seen);
    addCandidate(candidates, 'C:\\Program Files\\Java\\jdk-17', seen);
    addCandidate(candidates, 'C:\\Program Files\\Zulu\\zulu-17', seen);
    addCandidate(candidates, 'C:\\Program Files\\Android\\Android Studio\\jbr', seen);
    addCandidate(candidates, 'C:\\Program Files\\Android\\Android Studio\\jre', seen);
    addCandidate(candidates, 'C:\\Program Files\\JetBrains\\Android Studio\\jbr', seen);
    addHomesFromBase(candidates, 'C:\\Program Files\\Eclipse Adoptium', seen);
    addHomesFromBase(candidates, 'C:\\Program Files\\Microsoft', seen);
    addHomesFromBase(candidates, 'C:\\Program Files\\Java', seen);
    addHomesFromBase(candidates, 'C:\\Program Files\\Zulu', seen);
    addHomesFromBase(candidates, 'C:\\Program Files\\Android', seen);
    addHomesFromBase(candidates, 'C:\\Program Files\\JetBrains', seen);
    addHomesFromBase(candidates, 'C:\\Android', seen);
  } else {
    addCandidate(candidates, '/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home', seen);
    addCandidate(candidates, '/usr/lib/jvm/java-17-openjdk-amd64', seen);
    addCandidate(candidates, '/usr/lib/jvm', seen);
    addHomesFromBase(candidates, '/Library/Java/JavaVirtualMachines', seen);
    addHomesFromBase(candidates, '/usr/lib/jvm', seen);
  }

  return candidates;
}

function pickJavaHome() {
  const candidates = discoverJavaHomes();
  const scored = candidates
    .map(home => ({ home, major: javaMajorFromHome(home) }))
    .filter(item => item.major != null)
    .sort((a, b) => b.major - a.major);

  const best17Plus = scored.find(item => item.major >= 17);
  if (best17Plus) return best17Plus;

  const best11Plus = scored.find(item => item.major >= 11);
  if (best11Plus) return best11Plus;

  return null;
}

function configureJavaEnv() {
  const selected = pickJavaHome();
  if (!selected) {
    const message = [
      'No supported Java runtime (11+) was found for the Android build.',
      '',
      'Install JDK 17 and try again, or set JAVA_HOME before running the build.',
      'Recommended path on this project: C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.17.10-hotspot'
    ].join('\n');
    console.error(message);
    process.exit(1);
  }

  const env = { ...process.env, JAVA_HOME: selected.home };
  env.PATH = path.join(selected.home, 'bin') + path.delimiter + (env.PATH || '');

  console.log(`Using Java ${selected.major} at: ${selected.home}`);
  return env;
}

function main() {
  const env = configureJavaEnv();

  run('npm run prepare:web', { env });
  run('npx cap sync android', { env });
  run(`cd android && ${gradlew} ${gradleTask}`, { env });

  console.log('Android build completed successfully.');
}

main();
