# RSWAi_eeg_analysis

*You can keep other project helpers (e.g., ****`pre_post_val.m`****, ****`group_sleep_var.m`****, ****`task_para4plot.m`****, ****`groups_indx.m`****, ****`Fisher_transf.m`****, ****`donutchart.m`****, ****`daviolinplot.m`****) under ****`/helpers`**** as well.*

---

## Setup

1. **Clone/download** this repository.
2. Add FieldTrip (and optionally EEGLAB) to your MATLAB path and run `ft_defaults`.
3. Copy your template files into `/templates` **or** update paths in scripts (all paths are written with `<YOUR_PATH>` placeholders—set them once at the top of each script as instructed in comments).
4. Keep raw data and subject lists under `/data` (not committed).

---

## Input data

- **Raw EEG:** EGI high-density *.mff* per subject.
- **Sleep staging:** CSV/Excel with epoch codes (30-s epochs). Project uses the stage codes:
  - `200 = Wake, 100 = REM, -100 = N1, -200 = N2, -300 = N3`.
- **Subject list:** a MATLAB file (e.g., `subjects_files_2.mat`) with fields: `mff_file`, `scoring_csv`, `subject`, `group`.

---

## End-to-end workflow

### 1) Convert + initial preprocessing (all channels)

Use **`preper_sleep_data4.m`** (called by your batch script) to:

- Load *.mff*, apply **band-pass 0.5–45 Hz**, remove line noise (50 Hz & harmonics via DFT or notch),
- **Resample to 250 Hz**,
- Segment into **30-s epochs**,
- Align/sanitize staging vector length, and
- Save epoched FieldTrip data (`data`, `epoched_scoring`).

**Note on line noise:** The scripts support both a narrow **notch** and FieldTrip’s **DFT filter** (`cfg.dftfilter='yes'; cfg.dftfreq=[50 100 150];`). Choose one consistently.

### 2) REM-only artifact cleaning per subject

Run **`prep_REM_sleep_stages.m`** to:

- Select **REM** epochs only.
- Create **eyes** and **brain** datasets; **eyes electrodes** are set to `NaN` in brain data to preserve indexing.
- **Mark bad channels** per subject (edit the `bad_eyes_chn` / `bad_brain_chn` lists).
- Interactive inspection with `ft_databrowser` and trial/channel rejection with `ft_rejectvisual`.
- **ICA** (`ft_componentanalysis`, `method='runica'` by default). Use `plot_top_comp.m` for component maps; **manually** list components to remove.
- **Reconstruct** clean data with `ft_rejectcomponent`.
- **Interpolate** bad/missing channels with `Fix_bad_Chann` (uses `ft_channelrepair`) and `Fix_Miss_Chann`.
- Save `<subject>_clean_REM.mat` and a **`keep_track`** struct documenting: removed trials, removed channels, ICA components, etc.

### 3) Aggregate REM power per group

Use **`sleep_group_cal.m`** (REM-only) to:

- Load cleaned subject files per group folder,
- Interpolate/fix channels again for safety,
- Re-reference (`avg` or as configured), reorder labels if needed,
- Compute power with **`sleep_frequency_bands.m`** (bands: All, δ, θ, α, σ, β, γ), and
- Collect into `freq_control` and `freq_PD` (per-band cell arrays of FieldTrip `freq` structures).

### 4) Group statistics & figures

Run **`REM_GroupSpectralStats_Main.m`** to:

- Produce multi-band **topographies** per group: `topo_SpectralBands_3groups_multiFig.m` (Control, PD−RSWA, PD+RSWA).
- Compute **cluster-based T-maps** between groups: `Tmaps_3groups_multiFig.m` (uses `montecarlo_statistics3`).
- Plot ROI **violin plots** and run **pairwise tests**: `daviolinplot_3groups.m` / `daviolinplot_3groups_singleROI.m`.
- Run per-band **omnibus ANOVA**: `bands_ANOVA_3group.m` or full permutation ANOVA `ANOVA_3group_freq_new.m`.

> **Statistical note.** Pairwise tests/visualizations are treated as **post-hoc**. Use them after an omnibus ANOVA shows a significant group effect, or interpret with appropriate multiplicity control (e.g., BH-FDR with `FDR_corr.m`).

### 5) GML task × sleep figures

- **GML\_Sleep\_Correlation\_Plots.m** – scatter + regression (by subgroup) for any sleep metric vs GML improvement.
- **plot\_sleep2task\_diff\_size.m** – same but X = **REM%** (REM/TST×100), with **point size by RSWAi** via `RSWAi_2scattSize.m`.
- **daviolinplot\_RSWAi.m** – RSWAi distributions (phasic/tonic/any) for Control vs PD.
- **sleep\_donut.m** – group donut plots of sleep stage composition.

---

## Configuration & parameters

- **Filtering:** 0.5–45 Hz band-pass. Add DFT notch at 50/100/150 Hz as needed.
- **Epoching:** 30-s (aligned to staging). Ensure `scoring` length matches data length; script pads/trims accordingly.
- **Resampling:** to 250 Hz if original is 1000 Hz.
- **Stage codes:** `200=Wake, 100=REM, -100=N1, -200=N2, -300=N3`.
- **Frequency bands:** `[0.5–40/45], δ [0.5–4], θ [4–8], α [8–12], σ [12–15], β [15–25], γ [25–45]` (configurable).
- **Statistics:** BH-FDR via `FDR_corr.m`; permutation ANOVA via `ANOVA_3group_freq_new.m`.

---

## Manual steps & documentation

- **Bad channels:** set `bad_eyes_chn`, `bad_brain_chn` per subject before REM cleaning.
- **Visual rejection:** use `ft_rejectvisual` in `prep_REM_sleep_stages.m` (keeps NaNs to preserve indexing where necessary).
- **ICA components:** decide visually using `plot_top_comp.m`; list components to remove in the script. ECG-like components can also be saved separately.
- **Provenance:** the `keep_track` struct records removed channels, trials, and components for reporting.

---

## Troubleshooting

- **Line noise persists:** prefer FieldTrip’s `dftfilter` with `dftfreq=[50 100 150]`. Avoid stacking notch + DFT simultaneously.
- **Label mismatches (E257/VREF):** use `Fix_bad_Chann`/`Fix_Miss_Chann` and provided templates to normalize labels.
- **ICA fails or components look odd:** check referencing and that only brain channels (not eye channels) drive the ICA input.
- **Missing functions:** some plotting/stat helpers are third-party (`daviolinplot`, `donutchart`). Add them to the MATLAB path.

---

## How to cite

Lanir-Azaria S, Nir Y, Tauman R, Zitser J, Giladi N. (2023). *Beyond RBD: Covert REM sleep abnormalities in Parkinson’s disease*. npj Parkinson’s Disease.

---

## License

Choose and add a license (e.g., MIT, BSD-3-Clause). If unsure, MIT is a permissive default.

---

## Contact

Questions or issues? Please open an issue or contact **Saar Lanir-Azaria**.

[saarlan530@gmail.com](mailto:saarlan530@gmail.com)
