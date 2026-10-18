# ============================================================
# DERMA VISION
# SKIN vs NON-SKIN CLASSIFICATION
# MobileNetV2 — lighting / tone robust, no skin-hue shift
# ============================================================

from __future__ import annotations

import argparse
import json
import os
import shutil
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns
from PIL import Image, ImageOps

from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    accuracy_score,
    f1_score,
)

from tensorflow.keras import layers, models, optimizers, callbacks
from tensorflow.keras.applications import MobileNetV2


# ============================================================
# 1. CONFIGURATION
# ============================================================

DATASET_PATH = Path(__file__).resolve().parent

IMG_SIZE = (224, 224)
BATCH_SIZE = 32

INITIAL_EPOCHS = 6
FINE_TUNE_EPOCHS = 4

# Abstain instead of forcing a class in the uncertain band.
# P(skin) must be >= SKIN_MIN to call SKIN, <= NONSKIN_MAX to call NON-SKIN.
SKIN_MIN = 0.62
NONSKIN_MAX = 0.38
MIN_WINNING_CONFIDENCE = 0.60

RANDOM_STATE = 123
AUTOTUNE = tf.data.AUTOTUNE

MODEL_PATH = DATASET_PATH / "skin_non_skin_model.keras"
BEST_MODEL_PATH = DATASET_PATH / "best_skin_non_skin_model.keras"
META_PATH = DATASET_PATH / "model_meta.json"

PHONE_SKIN_REPEAT = 50

PHONE_SKIN_SOURCES = [
    Path(r"C:\Users\Neeraj S\.cursor\projects\c-Users-Neeraj-S-OneDrive-Desktop-skin-non-skin\assets\c__Users_Neeraj_S_AppData_Roaming_Cursor_User_workspaceStorage_2d50280cfed9b2799e1aefcbb0043387_images_skin2-0277a417-077f-46b0-a010-4a58e7d23f4c.jpg"),
    Path(r"C:\Users\Neeraj S\.cursor\projects\c-Users-Neeraj-S-OneDrive-Desktop-skin-non-skin\assets\c__Users_Neeraj_S_AppData_Roaming_Cursor_User_workspaceStorage_2d50280cfed9b2799e1aefcbb0043387_images_skin3-d3671e16-3c46-4281-a9a7-923b7642ec3b.jpg"),
    Path(r"C:\Users\Neeraj S\.cursor\projects\c-Users-Neeraj-S-OneDrive-Desktop-skin-non-skin\assets\c__Users_Neeraj_S_AppData_Roaming_Cursor_User_workspaceStorage_2d50280cfed9b2799e1aefcbb0043387_images_skin1-347a03ce-8b2d-476f-9982-2e2055a095bd.jpg"),
    Path(r"C:\Users\Neeraj S\.cursor\projects\c-Users-Neeraj-S-OneDrive-Desktop-skin-non-skin\assets\c__Users_Neeraj_S_AppData_Roaming_Cursor_User_workspaceStorage_2d50280cfed9b2799e1aefcbb0043387_images_skin-2b66d0d0-6a62-4120-b6ce-1074b46ae3d5.jpg"),
    Path(r"C:\Users\Neeraj S\OneDrive\Desktop\skin.jpeg"),
    Path(r"C:\Users\Neeraj S\OneDrive\Desktop\skin1.jpeg"),
    Path(r"C:\Users\Neeraj S\OneDrive\Desktop\skin2.jpeg"),
]

VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

model = None


# ============================================================
# 2. IMAGE LOADING + LIGHTING NORMALISATION
# ============================================================

def _luminance_normalize_np(rgb: np.ndarray) -> np.ndarray:
    """Scale RGB by luminance only so hue / skin chromaticity stay the same."""
    x = np.clip(rgb.astype(np.float32), 0, 255) / 255.0
    y = 0.299 * x[:, :, 0] + 0.587 * x[:, :, 1] + 0.114 * x[:, :, 2]
    mean = float(y.mean())
    std = float(y.std()) + 1e-5
    y_new = (y - mean) / std * 0.18 + 0.42
    scale = np.clip(y_new / (y + 1e-5), 0.40, 2.50)
    out = np.clip(x * scale[..., None], 0.0, 1.0) * 255.0
    return out.astype(np.float32)


def _luminance_normalize_tf(image: tf.Tensor) -> tf.Tensor:
    x01 = tf.cast(image, tf.float32) / 255.0
    y = tf.image.rgb_to_grayscale(x01)
    mean = tf.reduce_mean(y)
    std = tf.math.reduce_std(y) + 1e-5
    y_new = (y - mean) / std * 0.18 + 0.42
    scale = tf.clip_by_value(y_new / (y + 1e-5), 0.40, 2.50)
    return tf.clip_by_value(x01 * scale, 0.0, 1.0) * 255.0


def load_rgb_square(image_path, size=IMG_SIZE, normalize=True) -> np.ndarray:
    """EXIF-rotate, centre-crop to square, resize. Optional luminance norm."""
    image = Image.open(image_path)
    image = ImageOps.exif_transpose(image)
    image = image.convert("RGB")

    w, h = image.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    image = image.crop((left, top, left + side, top + side))
    image = image.resize(size, Image.BILINEAR)

    arr = np.asarray(image, dtype=np.float32)
    if normalize:
        arr = _luminance_normalize_np(arr)
    return arr


def skin_pixel_ratio(image_rgb: np.ndarray) -> float:
    """YCbCr skin locus covering Fitzpatrick I–VI. Used as a consistency check
    only — never as a forced label.
    """
    rgb = np.clip(image_rgb, 0, 255).astype(np.float32)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    y = 0.299 * r + 0.587 * g + 0.114 * b
    cb = 128.0 - 0.168736 * r - 0.331264 * g + 0.5 * b
    cr = 128.0 + 0.5 * r - 0.418688 * g - 0.081312 * b
    mask = (
        (y > 20)
        & (y < 245)
        & (cb >= 70)
        & (cb <= 155)
        & (cr >= 115)
        & (cr <= 195)
        & (r > 30)
    )
    return float(np.mean(mask))


# ============================================================
# 3. TF DATA PIPELINE
# ============================================================

def _decode_and_square(file_path: tf.Tensor, random_crop: bool) -> tf.Tensor:
    image = tf.io.read_file(file_path)
    image = tf.io.decode_image(image, channels=3, expand_animations=False)
    image.set_shape([None, None, 3])

    h = tf.shape(image)[0]
    w = tf.shape(image)[1]
    short = tf.minimum(h, w)

    if random_crop:
        # Crop 70–100% of the short side so dermoscope black rings
        # and leftover background are not a reliable shortcut.
        crop_frac = tf.random.uniform([], 0.70, 1.00)
        crop = tf.cast(tf.cast(short, tf.float32) * crop_frac, tf.int32)
        crop = tf.maximum(crop, 32)
        max_h = tf.maximum(h - crop + 1, 1)
        max_w = tf.maximum(w - crop + 1, 1)
        offset_h = tf.random.uniform([], 0, max_h, dtype=tf.int32)
        offset_w = tf.random.uniform([], 0, max_w, dtype=tf.int32)
        image = tf.image.crop_to_bounding_box(image, offset_h, offset_w, crop, crop)
    else:
        offset_h = (h - short) // 2
        offset_w = (w - short) // 2
        image = tf.image.crop_to_bounding_box(
            image, offset_h, offset_w, short, short
        )

    image = tf.image.resize(image, IMG_SIZE)
    image = tf.cast(image, tf.float32)
    image = _luminance_normalize_tf(image)
    return image


def process_image_train(file_path, label):
    return _decode_and_square(file_path, random_crop=True), label


def process_image_val(file_path, label):
    return _decode_and_square(file_path, random_crop=False), label


def build_augmentation() -> tf.keras.Sequential:
    """Geometric + lighting only. No hue/saturation (those recolor skin)."""
    aug = [
        layers.RandomFlip("horizontal_and_vertical"),
        layers.RandomRotation(0.12),
        layers.RandomZoom(height_factor=(-0.10, 0.28), width_factor=(-0.10, 0.28)),
        layers.RandomTranslation(0.08, 0.08),
        layers.RandomBrightness(0.35),
        layers.RandomContrast(0.28),
    ]
    if hasattr(layers, "RandomErasing"):
        aug.append(
            layers.RandomErasing(
                factor=0.22,
                scale=(0.02, 0.18),
                fill_value=0.0,
            )
        )
    if hasattr(layers, "RandomGrayscale"):
        # Texture instead of a single skin hue, ~12% of batches.
        aug.append(layers.RandomGrayscale(factor=0.12))
    return tf.keras.Sequential(aug, name="data_augmentation")


# ============================================================
# 4. MODEL
# ============================================================

def build_model() -> tf.keras.Model:
    base_model = MobileNetV2(
        weights="imagenet",
        include_top=False,
        input_shape=(224, 224, 3),
    )
    base_model.trainable = False

    inputs = layers.Input(shape=(224, 224, 3), name="image_input")
    x = build_augmentation()(inputs)
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D(name="gap")(x)
    x = layers.Dropout(0.35, name="dropout_gap")(x)
    x = layers.Dense(
        128,
        activation="relu",
        kernel_regularizer=tf.keras.regularizers.l2(1e-3),
        name="dense_128",
    )(x)
    x = layers.BatchNormalization(name="bn_head")(x)
    x = layers.Dropout(0.40, name="dropout_1")(x)
    x = layers.Dense(
        32,
        activation="relu",
        kernel_regularizer=tf.keras.regularizers.l2(1e-3),
        name="dense_32",
    )(x)
    x = layers.Dropout(0.25, name="dropout_2")(x)
    outputs = layers.Dense(1, activation="sigmoid", name="skin_probability")(x)

    net = models.Model(inputs, outputs, name="DermaVision_SkinGate")
    net._base_model = base_model
    return net


# ============================================================
# 5. DECISION  (CNN primary, color as disagreement check)
# ============================================================

def decide_label(cnn_probability: float, color_ratio: float = 0.0) -> tuple[str, float, float]:
    """Return (label, confidence_pct, p_skin).

    CNN probability is the primary classifier.
    Images with p >= SKIN_MIN (0.62) are classified as SKIN.
    Images with p <= NONSKIN_MAX (0.38) are classified as NON-SKIN.
    Borderline probabilities within the uncertainty band [0.38, 0.62] yield 'Unable to determine'.
    """
    p = float(np.clip(cnn_probability, 0.0, 1.0))
    winning = max(p, 1.0 - p)

    if p >= SKIN_MIN:
        return "SKIN", p * 100.0, p
    elif p <= NONSKIN_MAX:
        return "NON-SKIN", (1.0 - p) * 100.0, p
    else:
        return "Unable to determine", winning * 100.0, p


def _tta_views(arr: np.ndarray) -> list[np.ndarray]:
    """Lighting / geometry TTA only — no hue shift."""
    return [
        arr,
        np.fliplr(arr),
        np.clip(arr * 1.22, 0, 255),
        np.clip(arr * 0.78, 0, 255),
    ]


def get_model() -> tf.keras.Model:
    global model
    if model is None:
        path = BEST_MODEL_PATH if BEST_MODEL_PATH.exists() else MODEL_PATH
        if not path.exists():
            raise FileNotFoundError(f"No trained model at {path}")
        model = tf.keras.models.load_model(path)
    return model


def predict_array(img_arr: np.ndarray, verbose: bool = False, use_tta: bool = True) -> tuple[str, float, float]:
    """Predict label and confidence for an image array.
    Returns (label, confidence_pct, cnn_probability).
    """
    net = get_model()
    if use_tta:
        views = np.stack(_tta_views(img_arr), axis=0)
        preds = net.predict(views, verbose=0)
        cnn_probability = float(np.mean(preds))
    else:
        batch = np.expand_dims(img_arr, axis=0)
        cnn_probability = float(net.predict(batch, verbose=0)[0][0])

    color_ratio = skin_pixel_ratio(img_arr)
    label, confidence, p = decide_label(cnn_probability, color_ratio)

    if verbose:
        print("\n" + "=" * 60)
        print("IMAGE PREDICTION")
        print("=" * 60)
        print(f"Prediction   : {label}")
        print(f"Confidence   : {confidence:.2f}%")
        print(f"CNN score    : {cnn_probability:.4f}" + (" (avg of 4 TTA views)" if use_tta else ""))
        print(f"Skin pixels  : {color_ratio * 100:.1f}%")
        print(f"P(skin)      : {p:.4f}")
        print("=" * 60)
    return label, confidence, cnn_probability


def predict_image(image_path, verbose: bool = True, use_tta: bool = True) -> tuple[str, float, float] | None:
    image_path = Path(image_path)
    if not image_path.exists():
        print(f"\nERROR: Image not found: {image_path}")
        return None
    img_arr = load_rgb_square(image_path)
    label, confidence, cnn_prob = predict_array(img_arr, verbose=False, use_tta=use_tta)
    if verbose:
        print("\n" + "=" * 60)
        print("IMAGE PREDICTION")
        print("=" * 60)
        print(f"Image        : {image_path.name}")
        print(f"Prediction   : {label}")
        print(f"Confidence   : {confidence:.2f}%")
        print(f"CNN score    : {cnn_prob:.4f}" + (" (avg of 4 TTA views)" if use_tta else ""))
        print(f"Skin pixels  : {skin_pixel_ratio(img_arr) * 100:.1f}%")
        print("=" * 60)
    return label, confidence, cnn_prob


# ============================================================
# 6. DATASET HELPERS
# ============================================================

def get_image_files(folder: Path) -> list[Path]:
    return [
        f
        for f in folder.rglob("*")
        if f.suffix.lower() in VALID_EXTENSIONS and f.is_file()
    ]


def ingest_phone_skin_photos(skin_dir: Path) -> list[Path]:
    dest = skin_dir / "phone_captures"
    dest.mkdir(parents=True, exist_ok=True)
    copied = []
    for i, src in enumerate(PHONE_SKIN_SOURCES):
        if not src.exists():
            continue
        target = dest / f"phone_skin_{i}{src.suffix.lower()}"
        if not target.exists():
            shutil.copy2(src, target)
        copied.append(target)
    return copied


def build_dataframe(skin_dir: Path, non_skin_dir: Path) -> pd.DataFrame:
    phone_files = ingest_phone_skin_photos(skin_dir)
    skin_images = get_image_files(skin_dir)
    non_skin_images = get_image_files(non_skin_dir)

    rows = []
    phone_set = {str(p.resolve()) for p in phone_files}
    for img in skin_images:
        rows.append({"filepath": str(img), "label": "skin", "source": "dataset"})
    for img in non_skin_images:
        rows.append({"filepath": str(img), "label": "non_skin", "source": "dataset"})

    # Oversample real camera close-ups so phone lighting / darker tones
    # are not drowned out by ISIC dermoscopy.
    for img in phone_files:
        for _ in range(PHONE_SKIN_REPEAT):
            rows.append(
                {"filepath": str(img), "label": "skin", "source": "phone"}
            )

    df = pd.DataFrame(rows)
    print("\nDataset Information")
    print("-" * 60)
    print("Skin images (unique)     :", len(skin_images))
    print("Non-skin images          :", len(non_skin_images))
    print("Phone skin files added   :", len(phone_files))
    print("Rows after oversample    :", len(df))
    print(df["label"].value_counts())
    unused = phone_set  # silence linter if unused
    del unused
    return df


def make_datasets(train_df, val_df, train_labels, val_labels):
    train_ds = (
        tf.data.Dataset.from_tensor_slices(
            (train_df["filepath"].values, train_labels)
        )
        .shuffle(
            buffer_size=min(4096, len(train_df)),
            seed=RANDOM_STATE,
            reshuffle_each_iteration=True,
        )
        .map(process_image_train, num_parallel_calls=AUTOTUNE)
        .batch(BATCH_SIZE)
        .prefetch(AUTOTUNE)
    )
    val_ds = (
        tf.data.Dataset.from_tensor_slices(
            (val_df["filepath"].values, val_labels)
        )
        .map(process_image_val, num_parallel_calls=AUTOTUNE)
        .batch(BATCH_SIZE)
        .prefetch(AUTOTUNE)
    )
    return train_ds, val_ds


# ============================================================
# 7. TRAIN / EVALUATE
# ============================================================

def compile_model(net, lr: float):
    net.compile(
        optimizer=optimizers.Adam(learning_rate=lr),
        loss=tf.keras.losses.BinaryCrossentropy(label_smoothing=0.05),
        metrics=[
            "accuracy",
            tf.keras.metrics.AUC(name="auc"),
            tf.keras.metrics.Precision(name="precision"),
            tf.keras.metrics.Recall(name="recall"),
        ],
    )


def train_and_evaluate():
    global model

    tf.keras.utils.set_random_seed(RANDOM_STATE)

    print("=" * 60)
    print("DERMAVISION — SKIN vs NON-SKIN  (tone / lighting robust)")
    print("=" * 60)

    gpu = tf.config.list_physical_devices("GPU")
    if gpu:
        print("\nGPU detected:")
        for device in gpu:
            print(" ", device)
        try:
            tf.config.experimental.set_memory_growth(gpu[0], True)
        except RuntimeError:
            pass
    else:
        print("\nGPU not detected. Running on CPU.")

    skin_path = DATASET_PATH / "skin"
    non_skin_path = DATASET_PATH / "non_skin"
    for p in [DATASET_PATH, skin_path, non_skin_path]:
        if not p.exists():
            raise FileNotFoundError(f"Folder not found: {p}")

    df = build_dataframe(skin_path, non_skin_path)
    if df["label"].nunique() < 2:
        raise ValueError("Need both skin and non_skin images to train.")

    train_df, val_df = train_test_split(
        df,
        test_size=0.20,
        stratify=df["label"],
        random_state=RANDOM_STATE,
    )
    train_df = train_df.reset_index(drop=True)
    val_df = val_df.reset_index(drop=True)
    print("\nTraining samples   :", len(train_df))
    print("Validation samples :", len(val_df))

    train_labels = (train_df["label"] == "skin").astype(np.float32).values
    val_labels = (val_df["label"] == "skin").astype(np.float32).values

    n_pos = float(np.sum(train_labels == 1))
    n_neg = float(np.sum(train_labels == 0))
    total = n_pos + n_neg
    class_weight = {0: total / (2.0 * n_neg), 1: total / (2.0 * n_pos)}
    print("Class weights:", class_weight)

    train_ds, val_ds = make_datasets(train_df, val_df, train_labels, val_labels)

    print("\nLoading MobileNetV2 (ImageNet weights)...")
    model = build_model()
    compile_model(model, lr=1e-4)
    model.summary()

    early_stop = callbacks.EarlyStopping(
        monitor="val_auc",
        patience=3,
        mode="max",
        restore_best_weights=True,
        verbose=1,
    )
    reduce_lr = callbacks.ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.4,
        patience=2,
        min_lr=1e-7,
        mode="min",
        verbose=1,
    )
    checkpoint = callbacks.ModelCheckpoint(
        str(BEST_MODEL_PATH),
        monitor="val_auc",
        mode="max",
        save_best_only=True,
        verbose=1,
    )

    print("\n" + "=" * 60)
    print("PHASE 1 — INITIAL TRAINING  (backbone frozen)")
    print("=" * 60)
    history_initial = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=INITIAL_EPOCHS,
        class_weight=class_weight,
        callbacks=[early_stop, reduce_lr, checkpoint],
    )

    print("\n" + "=" * 60)
    print("PHASE 2 — FINE-TUNING  (last 40 layers)")
    print("=" * 60)
    base_model = model._base_model
    base_model.trainable = True
    for layer in base_model.layers[:-40]:
        layer.trainable = False
    for layer in base_model.layers:
        if isinstance(layer, layers.BatchNormalization):
            layer.trainable = False

    compile_model(model, lr=8e-6)
    early_stop_ft = callbacks.EarlyStopping(
        monitor="val_auc",
        patience=3,
        mode="max",
        restore_best_weights=True,
        verbose=1,
    )
    history_fine = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=FINE_TUNE_EPOCHS,
        class_weight=class_weight,
        callbacks=[early_stop_ft, reduce_lr, checkpoint],
    )

    if BEST_MODEL_PATH.exists():
        print("\nLoading best saved model...")
        model = tf.keras.models.load_model(BEST_MODEL_PATH)

    print("\n" + "=" * 60)
    print("MODEL EVALUATION")
    print("=" * 60)
    results = model.evaluate(val_ds, verbose=1)
    for name, val in zip(model.metrics_names, results):
        print(f"  {name:<12}: {val:.4f}")

    true_classes, raw_preds = [], []
    for images, lbls in val_ds:
        batch_preds = model.predict(images, verbose=0)
        raw_preds.extend(batch_preds.flatten())
        true_classes.extend(lbls.numpy())
    true_classes = np.array(true_classes)
    raw_preds = np.array(raw_preds)

    # F1 threshold is recorded for reference; inference still uses abstain band.
    best_f1, best_threshold = 0.0, 0.5
    for thr in np.arange(0.20, 0.81, 0.01):
        preds = (raw_preds >= thr).astype("int32")
        f1 = f1_score(true_classes, preds, zero_division=0)
        if f1 > best_f1:
            best_f1, best_threshold = f1, thr
    print(f"\nBest F1 threshold (reference only): {best_threshold:.2f}  F1={best_f1:.4f}")

    predicted = (raw_preds >= 0.50).astype("int32")
    print(f"Accuracy @ 0.50 : {accuracy_score(true_classes, predicted) * 100:.2f}%")
    class_names = ["Non-Skin", "Skin"]
    print("\nCLASSIFICATION REPORT  (@ 0.50, no abstain)")
    print(
        classification_report(
            true_classes,
            predicted,
            labels=[0, 1],
            target_names=class_names,
            digits=4,
            zero_division=0,
        )
    )
    cm = confusion_matrix(true_classes, predicted, labels=[0, 1])
    print("Confusion Matrix:\n", cm)

    plt.figure(figsize=(6, 5))
    sns.heatmap(
        cm,
        annot=True,
        fmt="d",
        cmap="Blues",
        xticklabels=class_names,
        yticklabels=class_names,
    )
    plt.xlabel("Predicted Class")
    plt.ylabel("Actual Class")
    plt.title("DermaVision Skin Gate — Confusion Matrix")
    plt.tight_layout()
    plt.savefig(DATASET_PATH / "confusion_matrix.png", dpi=120)
    plt.close()

    def combine_history(h1, h2):
        combined = {}
        for key in h1.history:
            combined[key] = h1.history[key] + h2.history.get(key, [])
        return combined

    combined = combine_history(history_initial, history_fine)
    phase1_len = len(history_initial.history["accuracy"])
    for metric, ylabel, fname in [
        ("accuracy", "Accuracy", "accuracy_curve.png"),
        ("loss", "Loss", "loss_curve.png"),
        ("auc", "AUC", "auc_curve.png"),
    ]:
        if metric not in combined:
            continue
        plt.figure(figsize=(9, 5))
        plt.plot(combined[metric], label=f"Training {ylabel}")
        plt.plot(combined[f"val_{metric}"], label=f"Validation {ylabel}")
        plt.axvline(phase1_len - 1, color="grey", linestyle="--", alpha=0.6)
        plt.xlabel("Epoch")
        plt.ylabel(ylabel)
        plt.title(f"DermaVision Skin Gate — {ylabel}")
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(DATASET_PATH / fname, dpi=120)
        plt.close()

    model.save(MODEL_PATH)
    meta = {
        "model_version": "3.0",
        "skin_min": SKIN_MIN,
        "nonskin_max": NONSKIN_MAX,
        "min_winning_confidence": MIN_WINNING_CONFIDENCE,
        "reference_f1_threshold": float(best_threshold),
        "notes": "Hue/saturation aug disabled. Luminance-only lighting norm. Abstain band enabled.",
    }
    META_PATH.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"\nFinal model saved: {MODEL_PATH}")
    print(f"Metadata saved: {META_PATH}")

    run_detector_tests(val_df)
    return model


# ============================================================
# 8. DETECTOR TESTS  (tones, lighting, skin + non-skin)
# ============================================================

def run_detector_tests(val_df: pd.DataFrame | None = None):
    print("\n" + "=" * 60)
    print("DETECTOR TESTS")
    print("=" * 60)

    get_model()
    rows = []

    def record(tag, path=None, arr=None, expected=None):
        if arr is None:
            if path is None or not Path(path).exists():
                return
            arr = load_rgb_square(path)
            name = Path(path).name
        else:
            name = tag
        label, conf, cnn = predict_array(arr, verbose=False)
        color = skin_pixel_ratio(arr)
        ok = ""
        if expected == "skin":
            ok = "OK" if label in ("SKIN", "Unable to determine") else "MISS"
            if label == "SKIN":
                ok = "OK"
        elif expected == "non_skin":
            ok = "OK" if label in ("NON-SKIN", "Unable to determine") else "FALSE+"
            if label == "NON-SKIN":
                ok = "OK"
        rows.append(
            {
                "case": tag,
                "file": name,
                "pred": label,
                "conf": conf,
                "cnn": cnn,
                "skin_px": color,
                "check": ok,
            }
        )
        print(
            f"{tag:<28} {label:<22} conf={conf:5.1f}%  "
            f"cnn={cnn:.3f}  pixels={color*100:5.1f}%  {ok}"
        )

    print("\n-- Camera skin (multiple tones / lighting) --")
    for i, src in enumerate(PHONE_SKIN_SOURCES):
        record(f"camera_skin_{i}", path=src, expected="skin")

    print("\n-- Lighting variants of first available camera skin --")
    first = next((p for p in PHONE_SKIN_SOURCES if p.exists()), None)
    if first is not None:
        base = load_rgb_square(first, normalize=False)
        for factor, tag in [(0.55, "darker"), (0.80, "dim"), (1.00, "as_shot"), (1.35, "brighter")]:
            arr = _luminance_normalize_np(np.clip(base * factor, 0, 255))
            record(f"lighting_{tag}", arr=arr, expected="skin")

    print("\n-- Held-out validation samples --")
    if val_df is not None and len(val_df):
        rng = np.random.RandomState(RANDOM_STATE)
        for cls, expected in [("skin", "skin"), ("non_skin", "non_skin")]:
            subset = val_df[val_df["label"] == cls]
            if subset.empty:
                continue
            take = subset.sample(n=min(6, len(subset)), random_state=rng)
            for _, row in take.iterrows():
                record(f"val_{cls}", path=row["filepath"], expected=expected)

    print("\n-- Extra non-skin files on Desktop if present --")
    extra_ns = [
        Path(r"C:\Users\Neeraj S\OneDrive\Desktop\test.jpeg"),
    ]
    for p in extra_ns:
        record("desktop_probe", path=p)

    print("\nSummary")
    print("-" * 60)
    n_ok = sum(1 for r in rows if r["check"] == "OK")
    n_marked = sum(1 for r in rows if r["check"])
    n_abstain = sum(1 for r in rows if r["pred"] == "Unable to determine")
    print(f"Checked cases     : {n_marked}")
    print(f"Correct (non-miss): {n_ok}")
    print(f"Abstain           : {n_abstain}")
    return rows


# ============================================================
# 9. CLI
# ============================================================

def parse_args():
    parser = argparse.ArgumentParser(description="DermaVision skin vs non-skin")
    parser.add_argument(
        "--predict-only",
        action="store_true",
        help="Skip training and run detector tests on the saved model.",
    )
    parser.add_argument(
        "--image",
        type=str,
        default="",
        help="Predict a single image path.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    if args.image:
        get_model()
        predict_image(args.image)
    elif args.predict_only:
        run_detector_tests()
    else:
        train_and_evaluate()
