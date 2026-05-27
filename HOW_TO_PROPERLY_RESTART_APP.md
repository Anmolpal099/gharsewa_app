# How to Properly Restart Flutter App After Code Changes

## ⚠️ **Important: Hot Reload is NOT Enough**

The image decoding fix requires a **full app restart**, not just a hot reload (R) or hot restart (Shift+R).

---

## ✅ **Proper Restart Steps**

### **Step 1: Stop the App Completely**

In your terminal where Flutter is running:

1. Press **`q`** to quit the app
2. Wait for the process to fully stop
3. You should see "Application finished" or similar message

**OR**

- Press **`Ctrl + C`** to force stop

---

### **Step 2: Clean Build (Recommended)**

```bash
cd e:\gharsewa
flutter clean
```

This ensures all old compiled code is removed.

---

### **Step 3: Start Fresh**

```bash
flutter run
```

Wait for the full compilation to complete (2-5 minutes for first build).

---

## 🔍 **Why Hot Reload Doesn't Work**

### **Hot Reload (R)** ❌
- Only updates UI changes
- Doesn't reload native code or imports
- Doesn't reinitialize state

### **Hot Restart (Shift+R)** ❌
- Restarts the app but keeps some cached code
- May not reload dart:ui changes
- Image decoder changes might not apply

### **Full Restart (q + flutter run)** ✅
- Completely recompiles the app
- Loads all new code including dart:ui changes
- Ensures image decoder fix is applied

---

## 📋 **Complete Restart Checklist**

- [ ] Press `q` in Flutter terminal to quit
- [ ] Run `flutter clean` (optional but recommended)
- [ ] Run `flutter run`
- [ ] Wait for full compilation
- [ ] Test AI Visual Assistant again

---

## 🎯 **After Restart**

The AI Visual Assistant should now:
- ✅ Load images without "_Namespace" error
- ✅ Display images correctly in annotation screen
- ✅ Allow marker placement
- ✅ Work with all image formats

---

## 🐛 **If Still Not Working**

### **1. Verify the Fix is in the Code**

Check `lib/presentation/panels/customer/ai_consultation/widgets/annotation_canvas.dart`:

```dart
// Should see this:
import 'dart:async';  // ✅ This line should be present

// In _loadImage() method, should see:
final completer = Completer<ui.Image>();
ui.decodeImageFromList(bytes, (result) {
  completer.complete(result);
});
final image = await completer.future;
```

### **2. Check Flutter Console for Errors**

Look for any error messages in the terminal where Flutter is running.

### **3. Try a Different Image**

- Try a simple JPG or PNG image
- Try a smaller image (< 5MB)
- Avoid complex formats initially

### **4. Check Image File Path**

Make sure the image file path doesn't have special characters or very long names.

---

## 💡 **Pro Tip**

After making code changes that affect:
- Native code (dart:ui, dart:io)
- Package imports
- State initialization
- Image/file handling

**Always do a full restart**, not just hot reload!

---

**Now try: Stop the app (q), run `flutter clean`, then `flutter run` again!** 🚀
