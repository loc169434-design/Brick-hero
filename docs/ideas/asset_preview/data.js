/* Shared by the offline viewer and the reproducible PNG exporter. */
window.TILE_PACK = {
  version: 1,
  colors: ['red', 'green', 'yellow', 'purple'],
  colorLabels: ['Đỏ · Khăn đỏ', 'Xanh · Mũ lá', 'Vàng · Mũ sắt', 'Tím · Mũ trùm'],
  expressions: ['idle', 'blink', 'chuckle', 'laugh', 'fear', 'relief', 'scream', 'gloat', 'hurt'],
  expressionLabels: ['Bình thường', 'Chớp mắt', 'Cười khúc khích', 'Cười lớn', 'Hoảng sợ', 'Thoát chết', 'Hét', 'Cười hiểm', 'Bị đau'],
  families: {
    training: { label: 'Thao trường', animations: ['idle', 'drop', 'land', 'combo', 'hurt', 'win', 'lose'] },
    orc_shield: { label: 'Orc đầu game', animations: ['idle', 'drop', 'land', 'combo', 'hurt', 'taunt', 'fear', 'near_miss', 'gloat', 'death', 'win', 'lose'] }
  },
  animations: {
    idle: { label: 'Chờ / chớp mắt', seconds: 2.4, loop: true, motion: 'idle', poses: [[0, 0], [.73, 1], [.79, 0]] },
    drop: { label: 'Rơi → chạm đất', seconds: .85, motion: 'drop', poses: [[0, 4], [.64, 8], [.86, 0]] },
    land: { label: 'Chạm đất / nảy', seconds: .65, motion: 'land', poses: [[0, 0], [.04, 8], [.55, 0]] },
    combo: { label: 'Nổ combo', seconds: 1.2, motion: 'burst', poses: [[0, 4], [.22, 6]] },
    hurt: { label: 'Trúng đòn', seconds: .75, motion: 'hurt', poses: [[0, 8], [.7, 0]] },
    taunt: { label: 'Cười chọc sau lượt hụt', seconds: 1.7, motion: 'laugh', poses: [[0, 2], [.17, 3], [.34, 2], [.51, 3], [.68, 2], [.85, 0]] },
    fear: { label: 'Sợ combo / sắp chết', seconds: 1.2, motion: 'fear', poses: [[0, 4]] },
    near_miss: { label: 'Sợ → thoát chết → cười', seconds: 2.8, motion: 'near_miss', poses: [[0, 4], [.38, 5], [.60, 2], [.71, 3], [.82, 2], [.91, 3]] },
    gloat: { label: 'Người chơi sắp thua', seconds: 1.7, motion: 'gloat', poses: [[0, 7], [.55, 2], [.7, 7]] },
    death: { label: 'Bị hạ / hét', seconds: 1.5, motion: 'death', poses: [[0, 4], [.14, 6]] },
    win: { label: 'Người chơi thắng', seconds: 1.8, motion: 'win', poses: [[0, 4], [.14, 6]] },
    lose: { label: 'Người chơi thua', seconds: 2, motion: 'lose', poses: [[0, 7], [.35, 3], [.52, 2], [.68, 3], [.84, 7]] }
  },
  export: { cell: 192, columns: 8, defaultFrames: 24, sourceCell: 128, sourceColumns: 3 },
  eventMap: {
    piece_spawn: 'drop', piece_landed: 'land', cells_cleared: 'combo',
    enemy_damaged: 'hurt', no_clear_turn: 'taunt', predicted_lethal_combo: 'fear',
    enemy_survives_predicted_lethal: 'near_miss', player_low_health: 'gloat',
    enemy_defeated: 'death', player_won: 'win', player_lost: 'lose'
  },
  priority: ['win', 'lose', 'death', 'combo', 'near_miss', 'fear', 'hurt', 'gloat', 'taunt', 'drop', 'land', 'idle'],
  notes: 'Visual asset pack only. Event names are an integration contract, not implemented game logic. No recorded voice or music.'
};
