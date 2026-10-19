/* Помощники геометрии: склейка множества деталей в один меш на материал (мало вызовов отрисовки),
   кабели-провисы, скруглённые коробки. */
import * as THREE from 'three';

/* склеить геометрии (каждая уже в мировых координатах) в одну */
export function mergeGeos(list) {
  let nv = 0, ni = 0;
  const gs = list.map(g => { const q = g.index ? g : indexize(g); nv += q.attributes.position.count; ni += q.index.count; return q; });
  const pos = new Float32Array(nv * 3), nor = new Float32Array(nv * 3), uv = new Float32Array(nv * 2);
  const idx = nv > 65535 ? new Uint32Array(ni) : new Uint16Array(ni);
  let ov = 0, oi = 0;
  for (const g of gs) {
    const p = g.attributes.position, n = g.attributes.normal, u = g.attributes.uv;
    pos.set(p.array, ov * 3);
    if (n) nor.set(n.array, ov * 3);
    if (u) uv.set(u.array, ov * 2);
    const ix = g.index.array;
    for (let i = 0; i < ix.length; i++) idx[oi + i] = ix[i] + ov;
    ov += p.count; oi += ix.length;
  }
  const out = new THREE.BufferGeometry();
  out.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  out.setAttribute('normal', new THREE.BufferAttribute(nor, 3));
  out.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  out.setIndex(new THREE.BufferAttribute(idx, 1));
  out.computeBoundingSphere();
  return out;
}
function indexize(g) {
  const n = g.attributes.position.count, a = new Uint32Array(n);
  for (let i = 0; i < n; i++) a[i] = i;
  g.setIndex(new THREE.BufferAttribute(a, 1)); return g;
}

/* пакет: add(геометрия, материал, позиция, поворот, масштаб) → build() раскладывает по мешам */
export function makeBatch() {
  const groups = new Map();
  const m4 = new THREE.Matrix4(), q = new THREE.Quaternion(), e = new THREE.Euler(), s = new THREE.Vector3(), p = new THREE.Vector3();
  return {
    add(geo, mat, x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, sx = 1, sy = 1, sz = 1) {
      const g = geo.clone();
      q.setFromEuler(e.set(rx, ry, rz)); m4.compose(p.set(x, y, z), q, s.set(sx, sy, sz));
      g.applyMatrix4(m4);
      if (!groups.has(mat)) groups.set(mat, []);
      groups.get(mat).push(g);
      return g;
    },
    /* уже готовая геометрия в мировых координатах */
    raw(geo, mat) { if (!groups.has(mat)) groups.set(mat, []); groups.get(mat).push(geo); },
    build(parent) {
      const meshes = [];
      for (const [mat, list] of groups) {
        /* режем на куски, чтобы индексы и отсечение по видимости работали лучше */
        for (let i = 0; i < list.length; i += 400) {
          const m = new THREE.Mesh(mergeGeos(list.slice(i, i + 400)), mat);
          parent.add(m); meshes.push(m);
        }
        list.forEach(g => g.dispose());
      }
      groups.clear();
      return meshes;
    },
  };
}

/* провис кабеля между точками a и b: парабола вниз на sag метров, с боковым уводом */
export function catenary(a, b, sag, n = 14, side = null) {
  const pts = [];
  for (let i = 0; i <= n; i++) {
    const t = i / n, k = 4 * t * (1 - t);
    const v = new THREE.Vector3().lerpVectors(a, b, t);
    v.y -= sag * k;
    if (side) v.addScaledVector(side, k);
    pts.push(v);
  }
  return pts;
}
export function cableGeo(pts, r, seg = 18, rad = 5) {
  return new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), seg, r, rad, false);
}

/* скруглённая коробка: профиль w×h с радиусом r, вытянут на d (центр в нуле) */
export function roundBox(w, h, d, r, bevel = 0.01) {
  const s = new THREE.Shape(), x = -w / 2, y = -h / 2;
  s.moveTo(x + r, y); s.lineTo(x + w - r, y); s.quadraticCurveTo(x + w, y, x + w, y + r);
  s.lineTo(x + w, y + h - r); s.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  s.lineTo(x + r, y + h); s.quadraticCurveTo(x, y + h, x, y + h - r);
  s.lineTo(x, y + r); s.quadraticCurveTo(x, y, x + r, y);
  const g = new THREE.ExtrudeGeometry(s, { depth: d - bevel * 2, bevelEnabled: bevel > 0, bevelThickness: bevel, bevelSize: bevel, bevelSegments: 2, curveSegments: 6 });
  g.translate(0, 0, -(d - bevel * 2) / 2);
  return g;
}
