const fs = require('fs');
const path = require('path');

class PatchExecutor {
    constructor(patchId, description) {
        this.patchId = patchId;
        this.description = description || 'No description';
        this.root = process.cwd();
        this.backupBaseDir = path.join(this.root, '.patch_backups');
        this.lastRootPointer = path.join(this.backupBaseDir, 'last_root.json');
    }

    execute(files) {
        console.log(`🚀 [PATCH ${this.patchId}] Applying: ${this.description}...`);
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const backupDir = path.join(this.backupBaseDir, `${this.patchId}_${timestamp}`);
        
        if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });

        const manifest = { patchId: this.patchId, timestamp: new Date().toISOString(), files: [] };

        try {
            files.forEach(f => {
                const targetPath = path.join(this.root, f.path);
                const backupPath = path.join(backupDir, f.path);
                const backupFileDir = path.dirname(backupPath);
                
                if (!fs.existsSync(backupFileDir)) fs.mkdirSync(backupFileDir, { recursive: true });

                if (fs.existsSync(targetPath)) {
                    fs.copyFileSync(targetPath, backupPath);
                    manifest.files.push({ path: f.path, action: 'modified' });
                    console.log(`📦 Backed up: ${f.path}`);
                } else {
                    manifest.files.push({ path: f.path, action: 'created' });
                    console.log(`✨ New file will be created: ${f.path}`);
                }

                const targetDir = path.dirname(targetPath);
                if (!fs.existsSync(targetDir)) fs.mkdirSync(targetDir, { recursive: true });
                
                fs.writeFileSync(targetPath, f.content.trim());
                console.log(`✅ Updated: ${f.path}`);
            });

            fs.writeFileSync(path.join(backupDir, 'manifest.json'), JSON.stringify(manifest, null, 2));
            fs.writeFileSync(this.lastRootPointer, JSON.stringify({ last_backup: backupDir }));
            console.log(`🏁 Patch ${this.patchId} applied successfully.`);
        } catch (e) {
            console.error(`❌ CRITICAL ERROR in Patch ${this.patchId}:`, e);
            console.log('⚠️  Initiating immediate internal rollback...');
            this.rollbackInternal(backupDir, manifest);
            process.exit(1);
        }
    }

    rollbackInternal(backupDir, manifest) {
        console.log('🔄 Rolling back changes...');
        manifest.files.forEach(f => {
             const targetPath = path.join(this.root, f.path);
             const backupPath = path.join(backupDir, f.path);
             try {
                 if (f.action === 'modified' && fs.existsSync(backupPath)) {
                     fs.copyFileSync(backupPath, targetPath);
                 } else if (f.action === 'created' && fs.existsSync(targetPath)) {
                     fs.unlinkSync(targetPath);
                 }
             } catch(e) { console.error(`Failed to revert ${f.path}`, e); }
        });
        console.log('🔄 Rollback complete.');
    }

    static async rollback() {
        const root = process.cwd();
        const pointerPath = path.join(root, '.patch_backups', 'last_root.json');
        if (!fs.existsSync(pointerPath)) { console.error('❌ No backup pointer found.'); process.exit(1); }
        const pointer = JSON.parse(fs.readFileSync(pointerPath, 'utf8'));
        const backupDir = pointer.last_backup;
        const manifestPath = path.join(backupDir, 'manifest.json');
        if (!fs.existsSync(manifestPath)) { console.error('❌ Manifest missing.'); process.exit(1); }
        const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
        console.log(`🔙 Rolling back Patch ${manifest.patchId}...`);
        
        manifest.files.forEach(f => {
            const targetPath = path.join(root, f.path);
            const backupPath = path.join(backupDir, f.path);
            if (f.action === 'modified' && fs.existsSync(backupPath)) {
                fs.copyFileSync(backupPath, targetPath);
                console.log(`dw Restored: ${f.path}`);
            } else if (f.action === 'created' && fs.existsSync(targetPath)) {
                fs.unlinkSync(targetPath);
                console.log(`🗑️ Deleted: ${f.path}`);
            }
        });
        console.log('✅ Rollback done.');
    }
}

if (process.argv.includes('--rollback')) { PatchExecutor.rollback(); }
module.exports = PatchExecutor;