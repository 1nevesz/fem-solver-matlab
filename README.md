# FEM Structural Solver — MATLAB

> A general-purpose Finite Element Method (FEM) solver for structural analysis, implemented in MATLAB. Supports spring systems, 2D/3D trusses, and 2D/3D frames.

Developed as part of the Mechatronics Engineering curriculum at **EESC-USP (São Carlos)**, based on the Direct Stiffness Method.

---

## Features

| Module | Element Type | DOFs/node | Status |
|--------|-------------|-----------|--------|
| `spring` | Spring assemblage | 1 | ✅ Done |
| `truss2d` | Plane truss | 2 (x, y) | ✅ Done |
| `truss3d` | Space truss | 3 (x, y, z) | 🔄 In progress |
| `frame2d` | Plane frame (beam-column) | 3 (x, y, θ) | 🔄 In progress |
| `frame3d` | Space frame | 6 (x,y,z,θx,θy,θz) | 📋 Planned |

---

## How It Works

All modules share the same FEM pipeline:

```
1. Define nodes, elements, material properties
2. Build local stiffness matrix [k]
3. Transform to global coordinates [K_e]
4. Assemble global stiffness matrix [K_G]
5. Apply boundary conditions
6. Solve: {U} = [K_G]^{-1} {F}
7. Recover reactions and internal forces
8. Plot: deformed shape + internal force diagrams
```

The only difference between elements is the **local stiffness matrix** and the **number of DOFs per node** — the assembly, boundary condition, and solve steps are identical across all modules.

---

## Getting Started

```matlab
cd fem-solver-matlab/
run('src/examples/run_truss2d_bridge.m')
```

No toolboxes required — only base MATLAB.

---

## Examples

### Spring System
Validates the solver against analytical solutions. Ideal for understanding the Direct Stiffness Method from scratch.

### Plane Truss — Howe Bridge
6 nodes, 9 bars. Computes nodal displacements, bar normal forces (tension/compression), and support reactions.

### Plane Truss — Warren Roof *(in progress)*
Classic roof truss geometry with vertical loading.

### Space Truss — Transmission Tower *(in progress)*
3D geometry demonstrating the extension of the 2D framework.

### Plane Frame *(in progress)*
Portal frame with combined axial, shear, and bending.

---

## Output

Each solver generates:
- **Console report** — displacements (mm), reactions (kN), normal forces (kN)
- **Deformed shape plot** — original (dashed) vs. deformed (amplified scale)
- **Internal force diagram** — tension (green) / compression (red)

---

## Project Structure

```
fem-solver-matlab/
├── src/
│   ├── core/           # Shared engine: assembly, BC, solver
│   ├── elements/       # Stiffness matrices per element type
│   ├── utils/          # Plotting, reporting
│   └── examples/       # Ready-to-run scripts
├── docs/               # Theory notes and derivations
├── tests/              # Validation against analytical solutions
├── legacy/             # Original monolithic solver (v0)
└── results/            # Output figures
```

---

## Roadmap

- [x] Core engine (assembly, BC, solver)
- [x] Spring element
- [x] Bar element 2D (plane truss)
- [ ] Bar element 3D (space truss)
- [ ] Beam element 2D (plane frame)
- [ ] Beam element 3D (space frame)
- [ ] App Designer GUI

---

## References

- Logan, D. L. — *A First Course in the Finite Element Method*, 5th ed.
- Beer & Johnston — *Mechanics of Materials*, 7th ed.
- Hibbeler, R. C. — *Structural Analysis*, 10th ed.

---

## Author

**Guilherme Neves** — Mechatronics Engineering, EESC-USP São Carlos  
Member of Tupã Formula SAE Electric

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?logo=linkedin)](https://linkedin.com/in/neves-eesc)
[![GitHub](https://img.shields.io/badge/GitHub-1nevesz-black?logo=github)](https://github.com/1nevesz)
