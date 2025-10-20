import argparse
from pathlib import Path
from typing import Optional, Dict, Union
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd



RooflineParam = tuple[float, float]
RooflineData = tuple[np.ndarray, np.ndarray, float, float]

__all__ = ["plot_roofline", "plot_roofline_from_df", "plot_roofline_from_csv"]

def plot_roofline(
    rooflines: dict[str, RooflineParam],
    workloads: Optional[Dict[str, float]] = None,
    filename: Union[str, Path] = "build/roofline.png",
) -> None:
    plt.figure(figsize=(8, 6))
    plt.title("Roofline Model", fontsize=14)
    plt.xlabel("Operational Intensity (MACs/Byte)")
    plt.ylabel("Performance (MACs/Cycle)")
    plt.grid(which="both", linestyle="--", linewidth=0.5)

    # 紀錄範圍
    xmin, xmax = np.inf, -np.inf
    ymin, ymax = np.inf, -np.inf
    oi_max = 0.0

    # 畫 roofline
    for i, (label, (peak_perf, bandwidth)) in enumerate(rooflines.items()):
        # 建立 roofline curve
        oi = np.logspace(-3, 3, 500)  # 改這裡：畫整個範圍
        perf = np.minimum(bandwidth * oi, peak_perf)
        color = "black" if i == len(rooflines) - 1 else "#aaaaaa"
        plt.plot(oi, perf, color=color, linewidth=2, label=label)


        # 找出水平段的起始位置（性能達到peak_perf的第一個oi）
        idx_flat = np.argmax(perf >= peak_perf * 0.999)
        oi_flat = oi[idx_flat]
        plt.text(
            1,               # 稍微右移
            peak_perf * 0.8,            # 稍微上移
            f"Peak = {peak_perf}",   # 顯示峰值
            fontsize=14,
            color=color,
            ha="left",
            va="bottom"
        )
        xmin = min(xmin, oi.min())
        xmax = max(xmax, oi.max())
        ymin = min(ymin, perf.min())
        ymax = max(ymax, perf.max())

    # 畫 workloads
    if workloads is not None:
        colors = [plt.get_cmap("tab10")(i) for i in range(len(workloads))]
        for (k, v), color in zip(workloads.items(), colors):
            plt.axvline(x=v, color=color, linestyle="--", label=f"{k} (OI = {v:.2f})")
            oi_max = max(oi_max, v)

    # 軸範圍
    plt.xscale("log")
    plt.yscale("log")
    plt.xlim(max(1e-3, xmin * 0.8), xmax * 1.2)
    plt.ylim(max(1e-3, ymin * 0.8), ymax * 1.2)
    plt.legend(fontsize=9, loc="best")

    # 儲存圖檔
    path = Path(filename)
    path.parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(path, dpi=300)
    plt.close()
    print(f"✅ Roofline plot saved to {path}")


def plot_roofline_from_df(df: pd.DataFrame, ofile: Union[str, Path]) -> None:
    # Load the roofline and workload data
    roofline_params = frozenset(zip(df["peak_performance"], df["peak_bandwidth"]))
    rooflines = {f"Roofline of Hardware {i}": v for i, v in enumerate(roofline_params)}
    workloads = {k: v for k, v in zip(df["layer"], df["intensity"])}
    print(f"{len(rooflines)} rooflines and {len(workloads)} workloads loaded.")

    # Plot the roofline model
    plot_roofline(rooflines, workloads, ofile)


def plot_roofline_from_csv(ifile: Union[str, Path], ofile: Union[str, Path]) -> None:
    df = pd.read_csv(ifile)
    plot_roofline_from_df(df, ofile)

def main():
    csv_path = "log/result.csv"  # 相對路徑
    png_path = "log/roofline.png"

    if not Path(csv_path).exists():
        raise FileNotFoundError(f"❌ {csv_path} not found! Please generate the CSV first.")

    plot_roofline_from_csv(csv_path, png_path)

if __name__ == "__main__":
    main()
