const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const mode = (process.argv[2] || 'debug').toLowerCase();
const isWin = process.platform === 'win32';
const javaBinName = isWin ? 'java.exe' : 'java';
const npmCmd = isWin ? 'npm.cmd' : 'npm';
const npxCmd = isWin ? 'npx.cmd' : 'npx';
const gradlew = isWin ? '.\\gradlew.bat' : './gradlew';
const gradleTask = mode === 'release' ? 'bundleRelease' : 'assembleDebug';
const MIN_JAVA_MAJOR = 17;
const MAX_JAVA_MAJOR = 22;

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    stdio: 'inherit',
    env: options.env || process.env,
    shell: false,
    windowsHide: true
  });

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0) {
    process.exit(result.status || 1);
  }
}

function javaMajorFromHome(home) {
  if (!home) return null;
  const javaPath = path.join(home, 'bin', javaBinName);
  if (!fs.existsSync(javaPath)) return null;

  const result = spawnSync(javaPath, ['-version'], { encoding: 'utf8', shell: false, windowsHide: true });
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
  addCandidate(candidates, process.env.JDK_HOME, seen);

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
    .filter(item => item.major >= MIN_JAVA_MAJOR && item.major <= MAX_JAVA_MAJOR)
    .sort((a, b) => b.major - a.major);

  return scored[0] || null;
}

function configureJavaEnv() {
  const selected = pickJavaHome();
  if (!selected) {
    const message = [
      `No supported Java runtime (${MIN_JAVA_MAJOR}-${MAX_JAVA_MAJOR}) was found for the Android build.`,
      '',
      'Install or point JAVA_HOME to JDK 17/21/22, or use Android Studio\'s bundled JBR.',
      'On many Windows setups that is: C:\\Program Files\\Android\\Android Studio\\jbr'
    ].join('\n');
    console.error(message);
    process.exit(1);
  }

  const env = { ...process.env, JAVA_HOME: selected.home };
  const currentPath = process.env.PATH || process.env.Path || '';
  env.PATH = path.join(selected.home, 'bin') + path.delimiter + currentPath;
  env.Path = env.PATH;

  console.log(`Using Java ${selected.major} at: ${selected.home}`);
  return env;
}

function main() {
  const env = configureJavaEnv();

  run(npmCmd, ['run', 'prepare:web'], { env });
  run(npxCmd, ['cap', 'sync', 'android'], { env });
  run(isWin ? 'cmd.exe' : gradlew, isWin ? ['/c', 'cd', '/d', 'android', '&&', gradlew, gradleTask] : [gradleTask], { env });

  console.log('Android build completed successfully.');
}

main();
