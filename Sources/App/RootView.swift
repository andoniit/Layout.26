import SwiftUI
import PhotosUI
#if os(iOS)
import UIKit
#endif

struct RootView: View {
    // MARK: - UI State
    @State private var showElementPicker = false
    @State private var selectedID: UUID? = nil
    @State private var isUIHidden = false
    @State private var showImageSettingsSheet = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showOnboarding = false
    // Bottom pill mode (tools vs settings)
    @State private var showTextSettingsSheet = false
    @State private var showNavBarSettingsSheet = false
    @State private var showAppearanceSheet = false
    @State private var showLayersSheet = false
    @State private var hideSelectionHighlight = false
    @State private var undoStack: [[CanvasItem]] = []
    @State private var isPlayMode = false
    @State private var showButtonSettingsSheet = false
    @State private var showShapeSettingsSheet = false
    @State private var canvasBackgroundColor: Color = Color(UIColor.systemGroupedBackground)

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }

    // Appearance
    enum AppearanceMode: String, CaseIterable {
        case system, light, dark
        var title: String { rawValue.capitalized }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    @AppStorage("appearanceMode_v2") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    private var appearanceMode: AppearanceMode { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }

    // MARK: - Unified Data Model
    enum ItemType: String, Equatable {
        case text, image, button, navbar, toggle, slider, shape
    }

    // Nested struct for dynamic Nav Bar tabs
    struct NavTab: Identifiable, Equatable {
        var id = UUID()
        var icon: String
        var title: String
    }

    struct CanvasItem: Identifiable, Equatable {
        var id = UUID()
        var type: ItemType
        var x: CGFloat
        var y: CGFloat
        var width: CGFloat
        var height: CGFloat
        var zIndex: Double = 0

        // Shared
        var text: String = "Text"
        var color: Color = .blue
        
        // Text Specific
        var fontSize: CGFloat = 24
        var isBold: Bool = false
        var isItalic: Bool = false
        var designIndex: Int = 0

        // Image Specific
        var uiImage: UIImage? = nil
        var shapeIndex: Int = 0
        var filterIndex: Int = 0

        // Button Specific
        var icon: String = "star.fill"
        var buttonMode: Int = 0
        var isGlass: Bool = true
        
        // Toggle Specific
        var isOn: Bool = false
        
        // Slider Specific
        var sliderValue: Double = 0.5
        
        // Shape Specific
        var cornerRadius: CGFloat = 16
        var opacity: Double = 1.0
        var shapeType: Int = 0 // 0 = Rectangle, 1 = Circle
        
        // NavBar Specific (Default 3 tabs)
        var navTabs: [NavTab] = [
            NavTab(icon: "doc.text.image", title: "Today"),
            NavTab(icon: "rocket.fill", title: "Games"),
            NavTab(icon: "square.stack.3d.up.fill", title: "Apps")
        ]
    }

    // Master Array
    @State private var items: [CanvasItem] = []

    func saveState() {
        undoStack.append(items)
        if undoStack.count > 30 { undoStack.removeFirst() }
    }

    // MARK: - Layer & Edit Actions
    func bringForward(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }), index < items.count - 1 else { return }
        saveState()
        items.swapAt(index, index + 1)
    }

    func sendBackward(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }), index > 0 else { return }
        saveState()
        items.swapAt(index, index - 1)
    }

    func duplicateItem(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        saveState()
        var newItem = items[index]
        newItem.id = UUID()
        newItem.x += 20
        newItem.y += 20
        items.append(newItem)
        selectedID = newItem.id
    }

    func deleteItem(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        saveState()
        items.remove(at: index)
        selectedID = nil
    }

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            let bottomInset = geo.safeAreaInsets.bottom

            ZStack {
                canvasBackgroundColor
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        if showTextSettingsSheet || showNavBarSettingsSheet || showImageSettingsSheet || showButtonSettingsSheet {
                            hideSelectionHighlight = true
                        } else {
                            if selectedID == nil && !showElementPicker {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isUIHidden.toggle()
                                }
                            }
                            selectedID = nil
                            showElementPicker = false
                        }
                    }

                ForEach($items) { $item in
                    let itemValue = $item.wrappedValue
                    switch itemValue.type {
                    case .image:
                        if let ui = itemValue.uiImage {
                            ImageElement(
                                id: itemValue.id,
                                uiImage: ui,
                                x: $item.x,
                                y: $item.y,
                                width: $item.width,
                                height: $item.height,
                                shapeIndex: $item.shapeIndex,
                                filterIndex: $item.filterIndex,
                                canvasSize: geo.size,
                                isSelected: selectedID == itemValue.id && !hideSelectionHighlight,
                                isPlayMode: isPlayMode,
                                onTapSelect: {
                                    if isPlayMode { return }
                                    selectedID = itemValue.id
                                    bringToFront(itemValue.id)
                                    hideSelectionHighlight = false
                                    showTextSettingsSheet = false
                                    showImageSettingsSheet = false
                                    showNavBarSettingsSheet = false
                                    showButtonSettingsSheet = false
                                    showShapeSettingsSheet = false
                                },
                                onDoubleTap: {
                                    if isPlayMode { return }
                                    selectedID = itemValue.id
                                    bringToFront(itemValue.id)
                                    hideSelectionHighlight = false
                                    showButtonSettingsSheet = false
                                    showImageSettingsSheet = true
                                    showShapeSettingsSheet = false
                                },
                                onGestureSelect: {
                                    if isPlayMode { return }
                                    if selectedID != itemValue.id {
                                        selectedID = itemValue.id
                                        bringToFront(itemValue.id)
                                    }
                                    if showImageSettingsSheet {
                                        showImageSettingsSheet = false
                                        hideSelectionHighlight = false
                                    }
                                }
                            )
                            .zIndex(selectedID == itemValue.id ? 1 : 0)
                        }
                    case .text:
                        TextElement(
                            id: itemValue.id,
                            text: $item.text,
                            x: $item.x,
                            y: $item.y,
                            width: $item.width,
                            fontSize: $item.fontSize,
                            isBold: $item.isBold,
                            isItalic: $item.isItalic,
                            designIndex: $item.designIndex,
                            color: $item.color,
                            canvasSize: geo.size,
                            isSelected: selectedID == itemValue.id && !hideSelectionHighlight,
                            isPlayMode: isPlayMode,
                            onTapSelect: {
                                if isPlayMode { return }
                                selectedID = itemValue.id
                                bringToFront(itemValue.id)
                                hideSelectionHighlight = false
                                showTextSettingsSheet = false
                                showNavBarSettingsSheet = false
                                showImageSettingsSheet = false
                                showButtonSettingsSheet = false
                                showShapeSettingsSheet = false
                            },
                            onDoubleTap: {
                                if isPlayMode { return }
                                selectedID = itemValue.id
                                bringToFront(itemValue.id)
                                hideSelectionHighlight = false
                                showButtonSettingsSheet = false
                                showTextSettingsSheet = true
                                showShapeSettingsSheet = false
                            },
                            onGestureSelect: {
                                if isPlayMode { return }
                                if selectedID != itemValue.id {
                                    selectedID = itemValue.id
                                    bringToFront(itemValue.id)
                                }
                                if showTextSettingsSheet {
                                    showTextSettingsSheet = false
                                    hideSelectionHighlight = false
                                }
                            },
                            onTapOutside: { selectedID = nil }
                        )
                        .zIndex(selectedID == itemValue.id ? 1 : 0)
                    case .button:
                        LiquidButtonElement(
                            item: itemValue,
                            x: $item.x,
                            y: $item.y,
                            isSelected: selectedID == itemValue.id && !hideSelectionHighlight,
                            isPlayMode: isPlayMode,
                            onTapSelect: {
                                if isPlayMode { return }
                                selectedID = itemValue.id
                                hideSelectionHighlight = false
                                showTextSettingsSheet = false
                                showImageSettingsSheet = false
                                showNavBarSettingsSheet = false
                                showButtonSettingsSheet = false
                                showShapeSettingsSheet = false
                            },
                            onDoubleTap: {
                                if isPlayMode { return }
                                selectedID = itemValue.id
                                bringToFront(itemValue.id)
                                hideSelectionHighlight = false
                                showTextSettingsSheet = false
                                showImageSettingsSheet = false
                                showNavBarSettingsSheet = false
                                showButtonSettingsSheet = true
                                showShapeSettingsSheet = false
                            },
                            onGestureSelect: {
                                if isPlayMode { return }
                                if selectedID != itemValue.id {
                                    selectedID = itemValue.id
                                    bringToFront(itemValue.id)
                                }
                            }
                        )
                        .zIndex(selectedID == itemValue.id ? 1 : 0)
                    
                    case .toggle:
                        ToggleElement(
                            item: itemValue,
                            x: $item.x,
                            y: $item.y,
                            isOn: $item.isOn,
                            isSelected: selectedID == itemValue.id && !hideSelectionHighlight,
                            isPlayMode: isPlayMode,
                            onTapSelect: {
                                selectedID = itemValue.id
                                bringToFront(itemValue.id)
                                hideSelectionHighlight = false
                                showTextSettingsSheet = false
                                showImageSettingsSheet = false
                                showNavBarSettingsSheet = false
                                showButtonSettingsSheet = false
                                showShapeSettingsSheet = false
                            },
                            onGestureSelect: {
                                if selectedID != itemValue.id {
                                    selectedID = itemValue.id
                                    bringToFront(itemValue.id)
                                }
                            }
                        )
                        .zIndex(selectedID == itemValue.id ? 1 : 0)
                    
                case .slider:
                    SliderElement(
                        item: itemValue,
                        x: $item.x,
                        y: $item.y,
                        value: $item.sliderValue,
                        isSelected: selectedID == itemValue.id && !hideSelectionHighlight,
                        isPlayMode: isPlayMode,
                        onTapSelect: {
                            if isPlayMode { return }
                            selectedID = itemValue.id
                            hideSelectionHighlight = false
                            showTextSettingsSheet = false
                            showImageSettingsSheet = false
                            showNavBarSettingsSheet = false
                            showButtonSettingsSheet = false
                            showShapeSettingsSheet = false
                        },
                        onGestureSelect: {
                            if isPlayMode { return }
                            if selectedID != itemValue.id {
                                selectedID = itemValue.id
                                bringToFront(itemValue.id)
                            }
                        }
                    )
                    .zIndex(selectedID == itemValue.id ? 1 : 0)
                    
                    case .shape:
                        ShapeElement(
                            item: itemValue,
                            x: $item.x,
                            y: $item.y,
                            width: $item.width,
                            height: $item.height,
                            isSelected: selectedID == itemValue.id && !hideSelectionHighlight,
                            isPlayMode: isPlayMode,
                            onTapSelect: {
                                if isPlayMode { return }
                                selectedID = itemValue.id
                                hideSelectionHighlight = false
                                showTextSettingsSheet = false
                                showImageSettingsSheet = false
                                showNavBarSettingsSheet = false
                                showButtonSettingsSheet = false
                                showShapeSettingsSheet = false
                            },
                            onDoubleTap: {
                                if isPlayMode { return }
                                selectedID = itemValue.id
                                bringToFront(itemValue.id)
                                hideSelectionHighlight = false
                                showTextSettingsSheet = false
                                showImageSettingsSheet = false
                                showNavBarSettingsSheet = false
                                showButtonSettingsSheet = false
                                showShapeSettingsSheet = true
                            },
                            onGestureSelect: {
                                if isPlayMode { return }
                                if selectedID != itemValue.id {
                                    selectedID = itemValue.id
                                    bringToFront(itemValue.id)
                                }
                            }
                        )
                        .zIndex(selectedID == itemValue.id ? 1 : 0)
                    
                    case .navbar:
                        NavBarElement(
                            item: itemValue,
                            x: $item.x,
                            y: $item.y,
                            width: $item.width,
                            canvasSize: geo.size,
                            isSelected: selectedID == itemValue.id && !hideSelectionHighlight,
                            isPlayMode: isPlayMode,
                            onTapSelect: {
                                if isPlayMode { return }
                                selectedID = itemValue.id
                                bringToFront(itemValue.id)
                                hideSelectionHighlight = false
                                showTextSettingsSheet = false
                                showImageSettingsSheet = false
                                showNavBarSettingsSheet = false
                                showButtonSettingsSheet = false
                                showShapeSettingsSheet = false
                            },
                            onDoubleTap: {
                                if isPlayMode { return }
                                selectedID = itemValue.id
                                bringToFront(itemValue.id)
                                hideSelectionHighlight = false
                                showButtonSettingsSheet = false
                                showNavBarSettingsSheet = true
                                showShapeSettingsSheet = false
                            },
                            onGestureSelect: {
                                if isPlayMode { return }
                                if selectedID != itemValue.id {
                                    selectedID = itemValue.id
                                    bringToFront(itemValue.id)
                                }
                            }
                        )
                        .zIndex(selectedID == itemValue.id ? 1 : 0)
                    }
                }

                // TOP BAR
                VStack {
                    HStack {
                        GlassCircleButton(systemName: "info.circle") {
                            // Trigger the sheet to open
                            showOnboarding = true
                        }
                        .frame(width: 36, height: 36)

                        Button(action: {
                            isPlayMode.toggle()
                            if isPlayMode { selectedID = nil }
                            impact(.medium)
                        }) {
                            Image(systemName: isPlayMode ? "stop.fill" : "play.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(isPlayMode ? .red : .primary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

                        Spacer()

                        GlassPill {
                            HStack(spacing: 12) {
                                IconButton(systemName: "arrow.uturn.left") {
                                    impact(.medium)
                                    if let previousState = undoStack.popLast() {
                                        items = previousState
                                        selectedID = nil
                                    }
                                }
                                .disabled(undoStack.isEmpty)
                                .opacity(undoStack.isEmpty ? 0.5 : 1.0)

                                IconButton(systemName: "square.stack.3d.up") {
                                    impact(.light)
                                    showLayersSheet = true
                                }
                                Menu {
                                    Picker("Theme", selection: $appearanceModeRaw) {
                                        ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                                            Label(mode.title, systemImage: mode == .system ? "circle.lefthalf.filled" : (mode == .light ? "sun.max" : "moon"))
                                                .tag(mode.rawValue)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, max(0, topInset - 16))
                    .opacity(isUIHidden ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: isUIHidden)

                    Spacer()

                    // BOTTOM BAR
                    if !isUIHidden {
                        Button(action: {
                            impact(.light)
                            withAnimation(.easeInOut(duration: 0.18)) {
                                showElementPicker = true
                                selectedID = nil
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Add Element")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                            .background(Capsule().fill(.ultraThinMaterial))
                            .overlay(Capsule().stroke(.quaternary, lineWidth: 1))
                            .foregroundStyle(.primary)
                            .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
                        }
                        .padding(.bottom, max(16, bottomInset))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // ELEMENT PICKER
                if showElementPicker {
                    ElementPickerSheet(
                        onPickText: {
                            addText(in: geo.size, topInset: topInset, bottomInset: bottomInset)
                            withAnimation(.interactiveSpring(response: 0.55, dampingFraction: 0.92)) {
                                showElementPicker = false
                            }
                        },
                        onPickButton: {
                            saveState()
                            let newButton = CanvasItem(
                                type: .button,
                                x: geo.size.width / 2,
                                y: geo.size.height / 2,
                                width: 150,
                                height: 60,
                                text: "Button",
                                fontSize: 20,
                                icon: "star.fill",
                                buttonMode: 0,
                                isGlass: true
                            )
                            items.append(newButton)
                            showElementPicker = false
                            selectedID = newButton.id
                        },
                        onPickToggle: {
                            saveState()
                            let newToggle = CanvasItem(
                                type: .toggle,
                                x: geo.size.width / 2,
                                y: geo.size.height / 2,
                                width: 51,
                                height: 31,
                                text: ""
                            )
                            items.append(newToggle)
                            showElementPicker = false
                            selectedID = newToggle.id
                        },
                        onPickSlider: {
                            saveState()
                            let newSlider = CanvasItem(
                                type: .slider,
                                x: geo.size.width / 2,
                                y: geo.size.height / 2,
                                width: 200,
                                height: 44,
                                sliderValue: 0.5
                            )
                            items.append(newSlider)
                            showElementPicker = false
                            selectedID = newSlider.id
                        },
                        onPickShape: {
                            saveState()
                            let newShape = CanvasItem(
                                type: .shape,
                                x: geo.size.width / 2,
                                y: geo.size.height / 2,
                                width: 150,
                                height: 150,
                                color: .blue,
                                cornerRadius: 24,
                                opacity: 1.0,
                                shapeType: 0
                            )
                            items.append(newShape)
                            showElementPicker = false
                            selectedID = newShape.id
                        },
                        onPickNavBar: {
                            saveState()
                            let newNav = CanvasItem(
                                type: .navbar,
                                x: geo.size.width / 2,
                                y: geo.size.height - 120,
                                width: 340,
                                height: 80,
                                fontSize: 20,
                            )
                            items.append(newNav)
                            showElementPicker = false
                            selectedID = newNav.id
                        },
                        onClose: {
                            withAnimation(.interactiveSpring(response: 0.55, dampingFraction: 0.92)) {
                                showElementPicker = false
                            }
                        },
                        selectedPhotoItem: $selectedPhotoItem
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, max(10, bottomInset + 8))
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
                }

                // BOTTOM OVERLAYS (Editors)
                VStack {
                    if showTextSettingsSheet, let id = selectedID, let idx = items.firstIndex(where: { $0.id == id && $0.type == .text }) {
                        VStack(spacing: 0) {
                            BottomTextEditView(
                                text: $items[idx].text,
                                fontSize: $items[idx].fontSize,
                                isBold: $items[idx].isBold,
                                isItalic: $items[idx].isItalic,
                                designIndex: $items[idx].designIndex,
                                color: $items[idx].color,
                                onDone: {
                                    showTextSettingsSheet = false
                                    hideSelectionHighlight = false
                                    selectedID = nil
                                }
                            )
                            Divider()
                            LayerControlsView(
                                onBringForward: { bringForward(id: id) },
                                onSendBackward: { sendBackward(id: id) },
                                onDuplicate: { duplicateItem(id: id) },
                                onDelete: { deleteItem(id: id) }
                            )
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.quaternary, lineWidth: 1))
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if showImageSettingsSheet, let id = selectedID, let idx = items.firstIndex(where: { $0.id == id && $0.type == .image }) {
                        VStack(spacing: 8) {
                            BottomImageEditView(
                                width: $items[idx].width,
                                height: $items[idx].height,
                                shapeIndex: $items[idx].shapeIndex,
                                filterIndex: $items[idx].filterIndex,
                                onDone: {
                                    showImageSettingsSheet = false
                                    hideSelectionHighlight = false
                                    selectedID = nil
                                }
                            )
                            Divider()
                            LayerControlsView(
                                onBringForward: { bringForward(id: id) },
                                onSendBackward: { sendBackward(id: id) },
                                onDuplicate: { duplicateItem(id: id) },
                                onDelete: { deleteItem(id: id) }
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if showButtonSettingsSheet, let id = selectedID, let i = items.firstIndex(where: { $0.id == id && $0.type == .button }) {
                        BottomButtonEditView(
                            text: $items[i].text,
                            icon: $items[i].icon,
                            fontSize: $items[i].fontSize,
                            buttonMode: $items[i].buttonMode,
                            isGlass: $items[i].isGlass,
                            color: $items[i].color,
                            onBringForward: { bringForward(id: id) },
                            onSendBackward: { sendBackward(id: id) },
                            onDuplicate: { duplicateItem(id: id) },
                            onDelete: { deleteItem(id: id) },
                            onDone: {
                                showButtonSettingsSheet = false
                                hideSelectionHighlight = false
                                selectedID = nil
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if showShapeSettingsSheet, let id = selectedID, let i = items.firstIndex(where: { $0.id == id && $0.type == .shape }) {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Edit Shape")
                                    .font(.system(size: 17, weight: .bold))
                                Spacer()
                                Button("Done") {
                                    showShapeSettingsSheet = false
                                    hideSelectionHighlight = false
                                    selectedID = nil
                                }
                                .font(.system(size: 16, weight: .semibold))
                            }

                            Picker("Shape Type", selection: $items[i].shapeType) {
                                Text("Rectangle").tag(0)
                                Text("Circle").tag(1)
                            }
                            .pickerStyle(.segmented)

                            HStack {
                                Text("W: \(Int(items[i].width))").font(.caption)
                                Slider(value: $items[i].width, in: 20...400)

                                if items[i].shapeType == 0 {
                                    Text("H: \(Int(items[i].height))").font(.caption)
                                    Slider(value: $items[i].height, in: 20...400)
                                }
                            }

                            if items[i].shapeType == 0 {
                                HStack {
                                    Text("Corner Radius").font(.caption).frame(width: 100, alignment: .leading)
                                    Slider(value: $items[i].cornerRadius, in: 0...min(items[i].width/2, items[i].height/2))
                                }
                            }

                            HStack {
                                Text("Opacity").font(.caption).frame(width: 60, alignment: .leading)
                                Slider(value: $items[i].opacity, in: 0.1...1.0)
                            }

                            Toggle("Glass Sheet Effect", isOn: $items[i].isGlass)
                                .tint(.blue)

                            ColorPicker("Shape Color", selection: $items[i].color)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.quaternary, lineWidth: 1))
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if showNavBarSettingsSheet, let id = selectedID, let i = items.firstIndex(where: { $0.id == id && $0.type == .navbar }) {
                        BottomNavBarEditView(
                            tabs: $items[i].navTabs,
                            width: $items[i].width,
                            fontSize: $items[i].fontSize,
                            color: $items[i].color,
                            onBringForward: { bringForward(id: id) },
                            onSendBackward: { sendBackward(id: id) },
                            onDuplicate: { duplicateItem(id: id) },
                            onDelete: { deleteItem(id: id) },
                            onDone: {
                                showNavBarSettingsSheet = false
                                hideSelectionHighlight = false
                                selectedID = nil
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedID)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showTextSettingsSheet)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showNavBarSettingsSheet)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showButtonSettingsSheet)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showShapeSettingsSheet)
                .zIndex(500)
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        saveState()
                        let newImage = CanvasItem(
                            type: .image,
                            x: geo.size.width * 0.5,
                            y: geo.size.height * 0.45,
                            width: 200,
                            height: 200 * (uiImage.size.height / uiImage.size.width),
                            uiImage: uiImage
                        )
                        items.append(newImage)
                        withAnimation { showElementPicker = false }
                        selectedPhotoItem = nil
                    }
                }
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .sheet(isPresented: $showAppearanceSheet) {
            VStack(spacing: 12) {
                HStack {
                    Text("Appearance")
                        .font(.system(size: 17, weight: .bold))
                    Spacer()
                    Button("Done") { showAppearanceSheet = false }
                        .font(.system(size: 16, weight: .semibold))
                }

                HStack(spacing: 16) {
                    // System
                    Button {
                        appearanceModeRaw = AppearanceMode.system.rawValue
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 22, weight: .semibold))
                            Text("System")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .opacity(appearanceMode == .system ? 1 : 0)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.quaternary, lineWidth: 1)
                                .opacity(appearanceMode == .system ? 1 : 0)
                        )
                    }
                    .buttonStyle(.plain)

                    // Light
                    Button {
                        appearanceModeRaw = AppearanceMode.light.rawValue
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 22, weight: .semibold))
                            Text("Light")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .opacity(appearanceMode == .light ? 1 : 0)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.quaternary, lineWidth: 1)
                                .opacity(appearanceMode == .light ? 1 : 0)
                        )
                    }
                    .buttonStyle(.plain)

                    // Dark
                    Button {
                        appearanceModeRaw = AppearanceMode.dark.rawValue
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 22, weight: .semibold))
                            Text("Dark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .opacity(appearanceMode == .dark ? 1 : 0)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.quaternary, lineWidth: 1)
                                .opacity(appearanceMode == .dark ? 1 : 0)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .sheet(isPresented: $showLayersSheet) {
            NavigationStack {
                List {
                    ForEach(items.reversed()) { item in
                        HStack {
                            Image(systemName: item.type == .text ? "textformat" : item.type == .image ? "photo" : item.type == .navbar ? "menubar.rectangle" : "button.horizontal")
                            Text(item.type == .text ? item.text : item.type == .image ? "Image" : item.type == .navbar ? "Nav Bar" : item.text)
                                .lineLimit(1)
                        }
                    }
                    .onMove { source, destination in
                        saveState()
                        var reversedItems = Array(items.reversed())
                        reversedItems.move(fromOffsets: source, toOffset: destination)
                        items = reversedItems.reversed()
                    }
                    .onDelete { indexSet in
                        saveState()
                        var reversedItems = Array(items.reversed())
                        reversedItems.remove(atOffsets: indexSet)
                        items = reversedItems.reversed()
                    }
                }
                .navigationTitle("Layers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { EditButton() }
            }
            .presentationDetents([.medium, .large])
            
            
        }
        .onAppear {
                        // 2. Added 0.1s delay to prevent SwiftUI presentation bugs
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showOnboarding = true
                        }
                    }
        .sheet(isPresented: $showOnboarding) {
                        OnboardingView(onContinue: {
                            showOnboarding = false
                        })
                        // 👈 Forces it to full-screen height, but still allows sliding down!
                        .presentationDetents([.large])
                    }
        
    }

    private func addText(in size: CGSize, topInset: CGFloat, bottomInset: CGFloat) {
        let safeTop = topInset + 90
        let safeBottom = size.height - (bottomInset + 140)
        let y = max(safeTop, min(size.height * 0.45, safeBottom))
        let x = size.width * 0.5

        saveState()
        let new = CanvasItem(
            type: .text,
            x: x,
            y: y,
            width: 320,
            height: 0,
            text: "Tap to edit text",
            fontSize: 44
        )
        items.append(new)
        selectedID = nil
    }
    
    private func index(for id: UUID) -> Int? { items.firstIndex(where: { $0.id == id }) }
    
    private func bringToFront(_ id: UUID) {
        saveState()
        if let i = index(for: id) {
            let item = items.remove(at: i)
            items.append(item)
        }
    }
    
    private func modeIcon(for mode: AppearanceMode) -> String {
        switch mode {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

// MARK: - BOTTOM SHEETS

private struct BottomTextEditView: View {
    @Binding var text: String
    @Binding var fontSize: CGFloat
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    @Binding var designIndex: Int
    @Binding var color: Color
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                TextField("Enter text...", text: $text)
                    .font(.system(size: 18))
                    .padding(14)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.blue)
                }
            }

            Divider()

            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "textformat.size.smaller")
                        .foregroundStyle(.secondary)
                    Slider(value: $fontSize, in: 14...160)
                    Image(systemName: "textformat.size.larger")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 20) {
                    Toggle("Bold", isOn: $isBold)
                        .toggleStyle(.button)
                        .tint(isBold ? .blue : .accentColor)

                    Toggle("Italic", isOn: $isItalic)
                        .toggleStyle(.button)
                        .tint(isItalic ? .blue : .accentColor)

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ColorPicker("", selection: $color, supportsOpacity: false)
                            .labelsHidden()
                    }
                }

                Picker("Design", selection: $designIndex) {
                    if #available(iOS 16.1, *) {
                        Text("Aa").tag(0)
                        Text("Aa").fontDesign(.rounded).tag(1)
                        Text("Aa").fontDesign(.serif).tag(2)
                        Text("Aa").fontDesign(.monospaced).tag(3)
                    } else {
                        Text("Default").tag(0)
                        Text("Rounded").tag(1)
                        Text("Serif").tag(2)
                        Text("Mono").tag(3)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct BottomImageEditView: View {
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    @Binding var shapeIndex: Int
    @Binding var filterIndex: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Edit Image")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Button("Done", action: onDone)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Picker("Shape Mask", selection: $shapeIndex) {
                Text("Rect").tag(0)
                Text("Square").tag(1)
                Text("Circle").tag(2)
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Filter").font(.caption).foregroundStyle(.secondary)
                Picker("Filter", selection: $filterIndex) {
                    Text("Normal").tag(0)
                    Text("B&W").tag(1)
                    Text("Warm").tag(2)
                    Text("Blur").tag(3)
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Size & Crop").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Text("W").font(.caption2).foregroundStyle(.secondary).frame(width: 15)
                    Slider(value: $width, in: 50...500)
                }
                if shapeIndex == 0 {
                    HStack {
                        Text("H").font(.caption2).foregroundStyle(.secondary).frame(width: 15)
                        Slider(value: $height, in: 50...500)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

private struct BottomButtonEditView: View {
    @Binding var text: String
    @Binding var icon: String
    @Binding var fontSize: CGFloat
    @Binding var buttonMode: Int
    @Binding var isGlass: Bool
    @Binding var color: Color
    
    let onBringForward: () -> Void
    let onSendBackward: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onDone: () -> Void

    let commonIcons = ["star.fill", "heart.fill", "bell.fill", "gearshape.fill", "paperplane.fill", "magnifyingglass", "plus", "trash.fill", "house.fill", "person.fill"]

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Edit Button")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Button("Done", action: onDone)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            HStack(spacing: 12) {
                Picker("Mode", selection: $buttonMode) {
                    Text("Both").tag(0)
                    Text("Icon").tag(1)
                    Text("Text").tag(2)
                }
                .pickerStyle(.segmented)
                
                Toggle("Glass", isOn: $isGlass)
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .tint(isGlass ? .blue : .primary)
            }
            
            HStack {
                Text("Button Color").font(.caption).foregroundStyle(.secondary)
                Spacer()
                ColorPicker("", selection: $color).labelsHidden()
            }
            
            if buttonMode == 0 || buttonMode == 2 {
                TextField("Button Text", text: $text)
                    .padding(10)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if buttonMode == 0 || buttonMode == 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("iOS Icon").font(.caption).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(commonIcons, id: \.self) { symbol in
                                Button(action: { icon = symbol }) {
                                    Image(systemName: symbol)
                                        .font(.system(size: 24))
                                        .frame(width: 44, height: 44)
                                        .background(icon == symbol ? Color.blue.opacity(0.2) : Color.clear)
                                        .foregroundColor(icon == symbol ? .blue : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Size").font(.caption).foregroundStyle(.secondary)
                Slider(value: $fontSize, in: 14...80)
            }
            
            Divider()
            
            LayerControlsView(
                onBringForward: onBringForward,
                onSendBackward: onSendBackward,
                onDuplicate: onDuplicate,
                onDelete: onDelete
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        
    }
}

private struct BottomNavBarEditView: View {
    @Binding var tabs: [RootView.NavTab]
    @Binding var width: CGFloat 
    @Binding var fontSize: CGFloat 
    @Binding var color: Color
    
    let onBringForward: () -> Void
    let onSendBackward: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onDone: () -> Void

    let commonIcons = ["doc.text.image", "rocket.fill", "square.stack.3d.up.fill", "gamecontroller.fill", "star.fill", "heart.fill", "bell.fill", "gearshape.fill", "house.fill", "person.fill", "magnifyingglass", "cart.fill"]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Edit NavBar")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Button("Done", action: onDone)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            HStack {
                // Tab Count Stepper
                Stepper(value: Binding(
                    get: { tabs.count },
                    set: { newCount in
                        if newCount > tabs.count && newCount <= 4 { tabs.append(RootView.NavTab(icon: "star.fill", title: "New Tab")) } 
                        else if newCount < tabs.count && newCount >= 2 { tabs.removeLast() }
                    }
                ), in: 2...4) {
                    Text("Tabs: \(tabs.count)")
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Color Picker for the glass & active tab
                HStack(spacing: 8) {
                    Image(systemName: "paintpalette").foregroundStyle(.secondary)
                    ColorPicker("", selection: $color, supportsOpacity: false).labelsHidden()
                }
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Width").font(.caption).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
                    Slider(value: $width, in: 200...500)
                }
                HStack {
                    Text("Scale").font(.caption).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
                    Slider(value: $fontSize, in: 16...44)
                }
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach($tabs) { $tab in
                        VStack(spacing: 8) {
                            TextField("Tab Title", text: $tab.title).textFieldStyle(.roundedBorder)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(commonIcons, id: \.self) { symbol in
                                        Button(action: { tab.icon = symbol }) {
                                            Image(systemName: symbol).font(.system(size: 20)).frame(width: 36, height: 36).background(tab.icon == symbol ? Color.blue.opacity(0.15) : Color.clear).foregroundColor(tab.icon == symbol ? .blue : .primary).clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            }
                        }.padding(12).background(Color.primary.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }.frame(maxHeight: 180)
            
            Divider()
            LayerControlsView(onBringForward: onBringForward, onSendBackward: onSendBackward, onDuplicate: onDuplicate, onDelete: onDelete)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.ultraThinMaterial))
        
        
    }
}


// MARK: - Element Picker
private struct ElementPickerSheet: View {
    let onPickText: () -> Void
    let onPickButton: () -> Void
    let onPickToggle: () -> Void
    let onPickSlider: () -> Void
    let onPickShape: () -> Void
    let onPickNavBar: () -> Void
    let onClose: () -> Void
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Spacer()
                Capsule().fill(Color.secondary.opacity(0.25)).frame(width: 42, height: 5)
                Spacer()
            }
            .padding(.top, 10)

            Text("Add Element")
                .font(.system(size: 22, weight: .bold))

            // -- Text Picker --
            Button(action: onPickText) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial).frame(width: 44, height: 44)
                        Image(systemName: "textformat").font(.system(size: 16, weight: .semibold))
                    }
                    Text("Text").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider().opacity(0.6)

            // -- Image Picker --
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        Image(systemName: "photo")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text("Image")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider().opacity(0.6)

            // -- Button Picker --
            Button(action: onPickButton) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        Image(systemName: "button.horizontal")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text("Button")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            
            Divider().opacity(0.6)
            
            // -- Toggle Picker --
            Button(action: onPickToggle) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        Image(systemName: "switch.2")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text("Toggle")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider().opacity(0.6)

            // -- Slider Picker --
            Button(action: onPickSlider) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        Image(systemName: "line.horizontal.3.decrease")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text("Slider")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            
            Divider().opacity(0.6)

            // -- Shape Picker --
            Button(action: onPickShape) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        Image(systemName: "square.on.circle")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text("Shape")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            
            Divider().opacity(0.6)
            
           
                        Button(action: onPickNavBar) {
                            HStack(spacing: 12) {
                                ZStack { // 👈 Added ZStack here!
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "menubar.rectangle")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text("Nav Bar")
                                    .font(.system(size: 17, weight: .semibold))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

            Button(action: onClose) {
                Text("Close")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.quaternary, lineWidth: 1))
        .shadow(radius: 24, y: 16)
    }
}

// MARK: - Layer Controls
struct LayerControlsView: View {
    let onBringForward: () -> Void
    let onSendBackward: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            LayerButton(icon: "square.3.layers.3d.down.backward", title: "Backward", action: onSendBackward)
            
            Divider().frame(height: 32)
            
            LayerButton(icon: "square.3.layers.3d.down.forward", title: "Forward", action: onBringForward)
            
            Divider().frame(height: 32)
            
            LayerButton(icon: "plus.square.on.square", title: "Duplicate", action: onDuplicate)
            
            Divider().frame(height: 32)
            
            LayerButton(icon: "trash", title: "Delete", color: .red, action: onDelete)
        }
        .padding(.vertical, 12)
        .background(.thickMaterial)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

private struct LayerButton: View {
    let icon: String
    let title: String
    var color: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

