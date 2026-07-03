import * as THREE from "https://unpkg.com/three@0.165.0/build/three.module.js";

const canvas = document.querySelector("#earth-scene");
const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: true,
  alpha: true,
  powerPreference: "high-performance"
});
renderer.setClearColor(0x000000, 0);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.08;

const scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0x05070b, 0.022);

const camera = new THREE.PerspectiveCamera(38, 1, 0.1, 100);
camera.position.set(0, 0.18, 7.2);

const earthGroup = new THREE.Group();
earthGroup.position.set(-0.72, 0, 0);
scene.add(earthGroup);

const textureLoader = new THREE.TextureLoader();
textureLoader.crossOrigin = "anonymous";
const textureBase = "https://unpkg.com/three-globe@2.31.1/example/img/";

function loadTexture(path) {
  return textureLoader.load(
    `${textureBase}${path}`,
    (texture) => {
      texture.colorSpace = THREE.SRGBColorSpace;
      texture.anisotropy = Math.min(8, renderer.capabilities.getMaxAnisotropy());
    },
    undefined,
    () => document.body.classList.add("scene-texture-fallback")
  );
}

function seededRandom(seed) {
  let state = seed;
  return () => {
    state |= 0;
    state = state + 0x6d2b79f5 | 0;
    let value = Math.imul(state ^ state >>> 15, 1 | state);
    value = value + Math.imul(value ^ value >>> 7, 61 | value) ^ value;
    return ((value ^ value >>> 14) >>> 0) / 4294967296;
  };
}

function createCloudTexture() {
  const cloudCanvas = document.createElement("canvas");
  cloudCanvas.width = 1024;
  cloudCanvas.height = 512;

  const ctx = cloudCanvas.getContext("2d");
  const random = seededRandom(42);
  ctx.clearRect(0, 0, cloudCanvas.width, cloudCanvas.height);
  ctx.filter = "blur(7px)";

  for (let band = 0; band < 7; band += 1) {
    const baseY = 58 + band * 64 + random() * 22;
    const count = 26 + Math.floor(random() * 16);

    for (let i = 0; i < count; i += 1) {
      const x = random() * cloudCanvas.width;
      const y = baseY + (random() - 0.5) * 64;
      const rx = 22 + random() * 82;
      const ry = 6 + random() * 24;
      ctx.globalAlpha = 0.1 + random() * 0.24;
      ctx.fillStyle = "#ffffff";
      ctx.beginPath();
      ctx.ellipse(x, y, rx, ry, random() * Math.PI, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  ctx.filter = "blur(2px)";
  for (let i = 0; i < 90; i += 1) {
    const x = random() * cloudCanvas.width;
    const y = random() * cloudCanvas.height;
    ctx.globalAlpha = 0.05 + random() * 0.12;
    ctx.fillStyle = "#ffffff";
    ctx.beginPath();
    ctx.ellipse(x, y, 10 + random() * 34, 4 + random() * 12, random() * Math.PI, 0, Math.PI * 2);
    ctx.fill();
  }

  const texture = new THREE.CanvasTexture(cloudCanvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = Math.min(8, renderer.capabilities.getMaxAnisotropy());
  texture.wrapS = THREE.RepeatWrapping;
  texture.wrapT = THREE.ClampToEdgeWrapping;
  return texture;
}

const earthGeometry = new THREE.SphereGeometry(1.72, 128, 128);
const earth = new THREE.Mesh(
  earthGeometry,
  new THREE.MeshStandardMaterial({
    map: loadTexture("earth-blue-marble.jpg"),
    bumpMap: loadTexture("earth-topology.png"),
    bumpScale: 0.065,
    roughness: 0.68,
    metalness: 0.02,
    emissive: new THREE.Color(0x061326),
    emissiveIntensity: 0.16
  })
);
earthGroup.add(earth);

const clouds = new THREE.Mesh(
  new THREE.SphereGeometry(1.748, 128, 128),
  new THREE.MeshStandardMaterial({
    map: createCloudTexture(),
    transparent: true,
    opacity: 0.35,
    depthWrite: false,
    roughness: 1,
    metalness: 0
  })
);
earthGroup.add(clouds);

const atmosphere = new THREE.Mesh(
  new THREE.SphereGeometry(1.91, 128, 128),
  new THREE.ShaderMaterial({
    uniforms: {
      glowColor: { value: new THREE.Color(0x8be4ff) }
    },
    vertexShader: `
      varying vec3 vNormal;

      void main() {
        vNormal = normalize(normalMatrix * normal);
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }
    `,
    fragmentShader: `
      uniform vec3 glowColor;
      varying vec3 vNormal;

      void main() {
        float rim = pow(0.78 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 2.25);
        gl_FragColor = vec4(glowColor, clamp(rim, 0.0, 0.34));
      }
    `,
    transparent: true,
    side: THREE.BackSide,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  })
);
earthGroup.add(atmosphere);

const halo = new THREE.Mesh(
  new THREE.SphereGeometry(2.08, 96, 96),
  new THREE.MeshBasicMaterial({
    color: 0x7cf2c6,
    transparent: true,
    opacity: 0.04,
    side: THREE.BackSide,
    blending: THREE.AdditiveBlending,
    depthWrite: false
  })
);
earthGroup.add(halo);

function createOrbit(radius, tube, color, opacity, rotation) {
  const orbit = new THREE.Mesh(
    new THREE.TorusGeometry(radius, tube, 10, 240),
    new THREE.MeshBasicMaterial({
      color,
      transparent: true,
      opacity,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    })
  );
  orbit.rotation.set(rotation.x, rotation.y, rotation.z);
  earthGroup.add(orbit);
  return orbit;
}

const orbits = [
  createOrbit(2.14, 0.006, 0x8be4ff, 0.26, { x: Math.PI * 0.56, y: 0.1, z: Math.PI * 0.08 }),
  createOrbit(2.28, 0.004, 0x7cf2c6, 0.2, { x: Math.PI * 0.66, y: 0.45, z: Math.PI * 0.26 }),
  createOrbit(2.46, 0.003, 0xffd08b, 0.13, { x: Math.PI * 0.48, y: -0.32, z: Math.PI * 0.41 })
];

function makeArc(start, end, height, color, opacity) {
  const points = [];
  const steps = 42;
  for (let i = 0; i <= steps; i += 1) {
    const t = i / steps;
    const angle = start + (end - start) * t;
    const radius = 1.86 + Math.sin(Math.PI * t) * height;
    points.push(new THREE.Vector3(
      Math.cos(angle) * radius,
      Math.sin(Math.PI * t) * 0.64 - 0.12,
      Math.sin(angle) * radius
    ));
  }

  const line = new THREE.Line(
    new THREE.BufferGeometry().setFromPoints(points),
    new THREE.LineBasicMaterial({
      color,
      transparent: true,
      opacity,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    })
  );
  earthGroup.add(line);
  return line;
}

const arcs = [
  makeArc(-2.6, -0.38, 0.46, 0x8be4ff, 0.48),
  makeArc(0.45, 2.44, 0.36, 0x7cf2c6, 0.38),
  makeArc(2.75, 4.72, 0.28, 0xffd08b, 0.3)
];

const satelliteGeometry = new THREE.SphereGeometry(0.035, 18, 18);
const satelliteMaterial = new THREE.MeshBasicMaterial({ color: 0xffffff });
const satellites = [
  { pivot: new THREE.Group(), radius: 2.15, speed: 0.34, tilt: [Math.PI * 0.56, 0.1, Math.PI * 0.08], phase: 0 },
  { pivot: new THREE.Group(), radius: 2.28, speed: -0.28, tilt: [Math.PI * 0.66, 0.45, Math.PI * 0.26], phase: 1.8 },
  { pivot: new THREE.Group(), radius: 2.46, speed: 0.22, tilt: [Math.PI * 0.48, -0.32, Math.PI * 0.41], phase: 3.2 }
].map((item) => {
  const mesh = new THREE.Mesh(satelliteGeometry, satelliteMaterial);
  mesh.position.x = item.radius;
  item.pivot.rotation.set(...item.tilt);
  item.pivot.add(mesh);
  earthGroup.add(item.pivot);
  return { ...item, mesh };
});

function createStarField(count, radius, color, size, opacity) {
  const geometry = new THREE.BufferGeometry();
  const positions = new Float32Array(count * 3);
  for (let i = 0; i < count; i += 1) {
    const r = radius + Math.random() * radius;
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos(2 * Math.random() - 1);
    positions[i * 3] = r * Math.sin(phi) * Math.cos(theta);
    positions[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta);
    positions[i * 3 + 2] = r * Math.cos(phi);
  }
  geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));

  const field = new THREE.Points(
    geometry,
    new THREE.PointsMaterial({
      color,
      size,
      transparent: true,
      opacity,
      depthWrite: false
    })
  );
  scene.add(field);
  return field;
}

const nearStars = createStarField(820, 12, 0xd8f2ff, 0.022, 0.72);
const farStars = createStarField(1200, 24, 0x8be4ff, 0.015, 0.34);

const keyLight = new THREE.DirectionalLight(0xffffff, 3.2);
keyLight.position.set(-4.8, 3.6, 5.4);
scene.add(keyLight);

const rimLight = new THREE.DirectionalLight(0x7cf2c6, 2.1);
rimLight.position.set(4.5, -2.4, -2.2);
scene.add(rimLight);

const warmLight = new THREE.PointLight(0xffd08b, 11, 18, 2.4);
warmLight.position.set(2.8, 1.6, 3.2);
scene.add(warmLight);

scene.add(new THREE.AmbientLight(0x96b6d8, 0.55));

const pointer = { x: 0, y: 0 };
const target = { x: 0, y: 0 };

window.addEventListener("pointermove", (event) => {
  target.x = (event.clientX / window.innerWidth - 0.5) * 2;
  target.y = (event.clientY / window.innerHeight - 0.5) * 2;
});

function resize() {
  const width = window.innerWidth;
  const height = window.innerHeight;
  const mobile = width < 760;
  const tablet = width < 1080;
  const pixelRatio = mobile ? 1.45 : Math.min(window.devicePixelRatio, 1.9);

  renderer.setPixelRatio(pixelRatio);
  renderer.setSize(width, height, false);

  camera.aspect = width / height;
  camera.fov = mobile ? 48 : tablet ? 42 : 38;
  camera.position.z = mobile ? 7.9 : tablet ? 7.5 : 7.15;
  camera.updateProjectionMatrix();

  const scale = mobile ? 0.72 : tablet ? 0.8 : 0.84;
  earthGroup.scale.setScalar(scale);
  earthGroup.position.x = mobile ? 0 : tablet ? -0.34 : -0.72;
  earthGroup.position.y = mobile ? -0.08 : 0;
}

window.addEventListener("resize", resize);
resize();

const clock = new THREE.Clock();

function render() {
  const elapsed = clock.getElapsedTime();
  const motion = reducedMotion.matches ? 0.22 : 1;

  pointer.x += (target.x - pointer.x) * 0.045;
  pointer.y += (target.y - pointer.y) * 0.045;

  earth.rotation.y = elapsed * 0.085 * motion;
  earth.rotation.x = Math.sin(elapsed * 0.14) * 0.025 * motion;
  clouds.rotation.y = elapsed * 0.135 * motion;
  atmosphere.rotation.y = elapsed * 0.04 * motion;
  halo.scale.setScalar(1 + Math.sin(elapsed * 1.2) * 0.014 * motion);

  orbits.forEach((orbit, index) => {
    orbit.rotation.z += (0.0008 + index * 0.00028) * motion;
    orbit.rotation.x += Math.sin(elapsed * 0.18 + index) * 0.00022 * motion;
  });

  arcs.forEach((arc, index) => {
    arc.material.opacity = (0.22 + Math.sin(elapsed * 1.1 + index * 1.7) * 0.14 + 0.2) * (index === 0 ? 0.78 : 0.62);
  });

  satellites.forEach((satellite) => {
    satellite.pivot.rotation.z = satellite.phase + elapsed * satellite.speed * motion;
    satellite.mesh.scale.setScalar(1 + Math.sin(elapsed * 3 + satellite.phase) * 0.16);
  });

  nearStars.rotation.y = elapsed * 0.004 * motion;
  farStars.rotation.y = -elapsed * 0.002 * motion;

  earthGroup.rotation.y += (pointer.x * 0.13 - earthGroup.rotation.y) * 0.026;
  earthGroup.rotation.x += (-pointer.y * 0.08 - earthGroup.rotation.x) * 0.026;
  camera.position.x += (pointer.x * 0.18 - camera.position.x) * 0.018;
  camera.position.y += (0.18 - pointer.y * 0.11 - camera.position.y) * 0.018;
  camera.lookAt(0, 0, 0);

  renderer.render(scene, camera);
}

function start() {
  renderer.setAnimationLoop(render);
}

function stop() {
  renderer.setAnimationLoop(null);
}

document.addEventListener("visibilitychange", () => {
  if (document.hidden) {
    stop();
    return;
  }
  start();
});

start();
