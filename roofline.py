import argparse
from pathlib import Path
from typing import Optional, Dict, Union
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import re


RooflineParam = tuple[float, float]  # (peak_perf, bandwidth)
RooflineData = tuple[np.ndarray, np.ndarray, float, float]

__all__ = ["plot_roofline", "plot_roofline_from_df", "plot_roofline_from_csv"]


# ==================================================================
# 🏗️ 主繪圖函式：支援從 CSV 算出的 (OI, Performance) 散點
# ==================================================================
def plot_roofline(
    rooflines: dict[str, RooflineParam],
    workloads: Optional[pd.DataFrame] = None,
    filename: Union[str, Path] = "build/roofline.png",
) -> None:
    plt.figure(figsize=(8, 6))
    plt.title("Roofline Model", fontsize=14)
    plt.xlabel("Operational Intensity (MACs/Byte)")
    plt.ylabel("Performance (MACs/Cycle)")
    plt.grid(which="both", linestyle="--", linewidth=0.5)

    # 範圍統計
    xmin, xmax = np.inf, -np.inf
    ymin, ymax = np.inf, -np.inf

    # ---------------------------------------------------------------
    # 畫 Roofline 曲線
    # ---------------------------------------------------------------
    for i, (label, (peak_perf, bandwidth)) in enumerate(rooflines.items()):
        oi = np.logspace(-3, 3, 500)
        perf = np.minimum(bandwidth * oi, peak_perf)
        color = "black" if i == len(rooflines) - 1 else "#aaaaaa"
        plt.plot(oi, perf, color=color, linewidth=2, label=label)

        # 標註 peak perf
        plt.text(
            oi[-1] * 0.7,
            peak_perf * 1.05,
            f"Peak = {peak_perf:.2f}",
            fontsize=10,
            color=color,
            ha="right",
        )
        xmin, xmax = min(xmin, oi.min()), max(xmax, oi.max())
        ymin, ymax = min(ymin, perf.min()), max(ymax, perf.max())

    # ---------------------------------------------------------------
    # 畫 workload 實測點
    # ---------------------------------------------------------------
    offsets = [
    (-50, 0), #左
    (50, 0),  #右
    (0, 50),  #上
    (0, -50), #下
    (-120, 80),    # 右
    (120, 80),   # 左
    (120, -80),    # 上
    (-120, -80),   # 下
    ]
    if workloads is not None and not workloads.empty:
        required_cols = {"layer", "macs", "dram_access", "cycles"}
    if not required_cols.issubset(workloads.columns):
        raise ValueError(f"❌ CSV 檔缺少欄位: {required_cols}")

    # 計算 OI 和 Performance
    workloads["OI"] = workloads["macs"] / workloads["dram_access"]
    workloads["Perf_raw"] = workloads["macs"] / workloads["cycles"]
    # 取得最上層 roofline (最高的 peak perf)
    max_roof = max(rooflines.values(), key=lambda x: x[0])
    peak_perf, bandwidth = max_roof
    # 根據 roofline 限制 Perf
    workloads["Perf"] = workloads.apply(
        lambda r: min(r["Perf_raw"], bandwidth * r["OI"], peak_perf), axis=1
    )

    colors = plt.get_cmap("tab20")(np.linspace(0, 1, len(workloads)))

    for idx, ((_, row), color) in enumerate(zip(workloads.iterrows(), colors)):
        plt.scatter(row["OI"], row["Perf"], color=color, s=60, edgecolors="black", zorder=5)
        xytext = offsets[idx % len(offsets)]
        
        match = re.match(r"(\w+)\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", str(row["layer"]))
        if match:
            name, b, ifm, ofm = match.groups()
            label = f"{name}\nB={b}, IFM={ifm}, OFM={ofm}"
        else:
            label = str(row["layer"])

        plt.annotate(
            f"{label}\nOI={row['OI']:.2f}\nPerf={row['Perf']:.2f}",
            xy=(row["OI"], row["Perf"]),
            xytext=xytext,
            textcoords='offset points',
            fontsize=8,
            arrowprops=dict(arrowstyle='->', color=color, lw=1)
        )
        xmin = min(xmin, row["OI"])
        xmax = max(xmax, row["OI"])
        ymin = min(ymin, row["Perf"])
        ymax = max(ymax, row["Perf"])

    # ---------------------------------------------------------------
    # 軸設定與輸出
    # ---------------------------------------------------------------
    plt.xscale("log")
    plt.yscale("log")
    plt.xlim(max(1e-3, xmin * 0.8), xmax * 1.5)
    plt.ylim(max(1e-3, ymin * 0.8), ymax * 1.5)
    plt.legend(fontsize=9, loc="best")

    path = Path(filename)
    path.parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(path, dpi=300)
    plt.close()
    print(f"✅ Roofline plot saved to {path}")


# ==================================================================
# 🧮 從 DataFrame 載入 Roofline 與 Workload
# ==================================================================
def plot_roofline_from_df(df: pd.DataFrame, ofile: Union[str, Path]) -> None:
    # Roofline 資料
    roofline_params = frozenset(zip(df["peak_performance"], df["peak_bandwidth"]))
    rooflines = {f"Roofline {i+1}": v for i, v in enumerate(roofline_params)}

    # Workload 資料
    workloads = df[["layer", "macs", "dram_access", "cycles"]].copy()

    print(f"{len(rooflines)} rooflines and {len(workloads)} workloads loaded.")
    plot_roofline(rooflines, workloads, ofile)


# ==================================================================
# 📂 從 CSV 載入
# ==================================================================
def plot_roofline_from_csv(ifile: Union[str, Path], ofile: Union[str, Path]) -> None:
    df = pd.read_csv(ifile)
    plot_roofline_from_df(df, ofile)


# ==================================================================
# 🚀 Main
# ==================================================================
def main():
    parser = argparse.ArgumentParser(description="Plot a Roofline model from a CSV file.")
    parser.add_argument(
        "--csv",
        type=str,
        default="log/GEMM_no_mem_results.csv",
        help="Path to input CSV file (default: log/GEMM_no_mem_results.csv)",
    )
    parser.add_argument(
        "--out",
        type=str,
        default="log/roofline.png",
        help="Path to output PNG file (default: log/roofline_no_mem.png)",
    )
    args = parser.parse_args()

    csv_path = Path(args.csv)
    png_path = Path(args.out)

    if not csv_path.exists():
        raise FileNotFoundError(f"❌ {csv_path} not found! Please generate the CSV first.")

    plot_roofline_from_csv(csv_path, png_path)


if __name__ == "__main__":
    main()
