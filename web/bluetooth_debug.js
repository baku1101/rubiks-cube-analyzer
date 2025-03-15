// Web Bluetooth APIデバッグ用ユーティリティ
class BluetoothDebugger {
    constructor() {
        this.isDebugEnabled = true;
        this.logElement = null;
        this.debugPanel = null;
        
        // DOMContentLoadedイベントで初期化
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.initializeDebugUI());
        } else {
            this.initializeDebugUI();
        }
    }

    // デバッグUIの初期化
    initializeDebugUI() {
        // bodyが読み込まれるまで待機
        if (!document.body) {
            setTimeout(() => this.initializeDebugUI(), 100);
            return;
        }

        // デバッグパネルの作成
        this.debugPanel = document.createElement('div');
        this.debugPanel.style.cssText = `
            position: fixed;
            bottom: 0;
            right: 0;
            width: 400px;
            height: 300px;
            background: rgba(0, 0, 0, 0.8);
            color: #fff;
            padding: 10px;
            font-family: monospace;
            font-size: 12px;
            z-index: 9999;
            display: flex;
            flex-direction: column;
        `;

        // ツールバーの作成
        const toolbar = document.createElement('div');
        toolbar.style.cssText = `
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        `;

        // タイトル
        const title = document.createElement('div');
        title.textContent = 'Bluetooth Debug';
        title.style.fontWeight = 'bold';
        toolbar.appendChild(title);

        // ボタンコンテナ
        const buttonContainer = document.createElement('div');
        buttonContainer.style.cssText = `
            display: flex;
            gap: 5px;
        `;

        // Bluetoothインターナルを開くボタン
        const internalButton = document.createElement('button');
        internalButton.textContent = 'Bluetooth Internals';
        internalButton.onclick = () => window.open('chrome://bluetooth-internals/', '_blank');
        buttonContainer.appendChild(this.styleButton(internalButton));

        // DevToolsを開くボタン
        const devToolsButton = document.createElement('button');
        devToolsButton.textContent = 'DevTools';
        devToolsButton.onclick = () => {
            if (window.bluetoothDebugger) {
                window.bluetoothDebugger.log('DevToolsを開く: Ctrl+Shift+I', 'info');
            }
        };
        buttonContainer.appendChild(this.styleButton(devToolsButton));

        // クリアボタン
        const clearButton = document.createElement('button');
        clearButton.textContent = 'Clear';
        clearButton.onclick = () => this.clearLogs();
        buttonContainer.appendChild(this.styleButton(clearButton));

        toolbar.appendChild(buttonContainer);
        this.debugPanel.appendChild(toolbar);

        // ログエリアのコンテナ
        const logContainer = document.createElement('div');
        logContainer.style.cssText = `
            flex: 1;
            overflow-y: auto;
            border: 1px solid #444;
            padding: 5px;
            margin-top: 5px;
            background: rgba(0, 0, 0, 0.5);
        `;

        // ログ表示エリア
        this.logElement = document.createElement('div');
        logContainer.appendChild(this.logElement);
        this.debugPanel.appendChild(logContainer);

        document.body.appendChild(this.debugPanel);
        this.log('デバッグパネルを初期化しました', 'success');
    }

    // ボタンのスタイル適用
    styleButton(button) {
        button.style.cssText = `
            padding: 3px 8px;
            background: #444;
            color: #fff;
            border: none;
            border-radius: 3px;
            cursor: pointer;
            font-size: 11px;
            transition: background-color 0.2s;
        `;
        button.addEventListener('mouseover', () => button.style.backgroundColor = '#555');
        button.addEventListener('mouseout', () => button.style.backgroundColor = '#444');
        return button;
    }

    // ログの追加
    log(message, type = 'info') {
        if (!this.isDebugEnabled) return;
        
        // ログ要素がまだ作成されていない場合はコンソールのみに出力
        if (!this.logElement) {
            console.log(`[Bluetooth Debug] ${message}`);
            return;
        }

        const timestamp = new Date().toLocaleTimeString();
        const logItem = document.createElement('div');
        logItem.style.cssText = `
            margin: 2px 0;
            padding: 2px 5px;
            border-left: 3px solid ${this.getTypeColor(type)};
            background: rgba(255, 255, 255, 0.1);
        `;
        logItem.textContent = `[${timestamp}] ${message}`;
        
        this.logElement.appendChild(logItem);
        this.logElement.scrollTop = this.logElement.scrollHeight;

        // コンソールにも出力
        console.log(`[Bluetooth Debug] ${message}`);
    }

    // ログタイプに応じた色を取得
    getTypeColor(type) {
        switch (type) {
            case 'error': return '#ff4444';
            case 'warn': return '#ffbb33';
            case 'success': return '#00C851';
            default: return '#33b5e5';
        }
    }

    // ログのクリア
    clearLogs() {
        if (this.logElement) {
            this.logElement.innerHTML = '';
            this.log('ログをクリアしました', 'info');
        }
    }

    // Bluetooth操作のモニタリング
    monitorBluetoothOperations() {
        if (!navigator.bluetooth) {
            this.log('Web Bluetooth APIは利用できません', 'error');
            return;
        }

        // デバイスの要求をモニター
        const originalRequestDevice = navigator.bluetooth.requestDevice;
        navigator.bluetooth.requestDevice = async (...args) => {
            this.log('requestDevice called with options:', 'info');
            this.log(JSON.stringify(args[0], null, 2));
            
            try {
                const device = await originalRequestDevice.apply(navigator.bluetooth, args);
                this.log(`Device selected: ${device.name || 'unnamed'}`, 'success');
                return device;
            } catch (error) {
                this.log(`requestDevice error: ${error.message}`, 'error');
                throw error;
            }
        };

        this.log('Bluetooth操作のモニタリングを開始しました', 'success');
    }

    // GANキューブ固有のデバッグ情報
    debugGANCube(data) {
        // コマンドの種類を判定
        const command = data[3];
        let commandType = 'Unknown';
        
        switch (command) {
            case 0x01:
                commandType = 'Move Data';
                break;
            case 0xED:
                commandType = 'Cube State';
                break;
            case 0xEF:
                commandType = 'Battery Status';
                break;
        }

        this.log(`GAN Cube Command: ${commandType} (0x${command.toString(16)})`, 'info');
        this.log(`Raw Data: ${Array.from(data).map(b => '0x' + b.toString(16)).join(', ')}`, 'info');
    }
}

// DOMの準備ができてからデバッガーインスタンスを作成
window.addEventListener('load', () => {
    window.bluetoothDebugger = new BluetoothDebugger();
    window.bluetoothDebugger.monitorBluetoothOperations();
});