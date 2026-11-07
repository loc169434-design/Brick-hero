"""Audit current exported assets and write handoff; never modifies game artwork."""
from pathlib import Path
import hashlib,json,subprocess
import numpy as np
from scipy import ndimage as ndi
from PIL import Image,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;ROOT=D.parents[2];A=ROOT/'assets/characters/hero_rig'
history=[json.loads(p.read_text()) for p in sorted(D.glob('metrics_round_*.json'))]
assert [r['round'] for r in history]==list(range(1,9))
corrections=[json.loads(p.read_text()) for p in sorted((D/'corrections').glob('[0-9][0-9]/metrics_round_08.json'))]
m=corrections[-1];items=json.loads((D/'new_items.json').read_text())['items']
assert len(items)==3
REF=Image.open(ROOT/'assets/characters/hero_rookie/anim/fresh_idle.png').convert('RGBA').crop((0,0,512,512))
assert np.array_equal(np.array(REF),np.array(Image.open(D/'ref.png')))
assert np.array_equal(np.array(Image.open(A/'parts/head.png')),np.array(Image.open(A/'heads/bare_normal.png')))
j=json.loads((A/'joints.json').read_text());old=json.loads(subprocess.check_output(['git','show','origin/core/world-life:assets/characters/hero_rig/joints.json'],cwd=ROOT))
assert j['order']==old['order'] and j['joints'].keys()==old['joints'].keys()
assert len(list((A/'parts').glob('*.png')))==17 and len(list((A/'heads').glob('*.png')))==18
assert len(list((A/'gear').rglob('*.png')))==28 and len(list((A/'item_icons').glob('*.png')))==3
records=[];outside=0
for p in sorted(A.rglob('*.png')):
 im=Image.open(p);box=im.getbbox()
 assert im.size==(512,512) and im.mode=='RGBA' and box and min(box[:2])>0 and max(box[2:])<512,p
 role=p.relative_to(A).parts[0]
 row={'path':str(p.relative_to(ROOT)),'role':role,'size':[512,512],'mode':'RGBA','bbox':box,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
 if role=='gear':
  parent=np.array(Image.open(A/'parts'/p.name))[:,:,3]>0
  count=int(((np.array(im)[:,:,3]>0)&(ndi.distance_transform_edt(~parent)>24)).sum());outside+=count;row['outside_parent_plus24']=count
 records.append(row)
assert len(records)==66 and outside==0
assert all(c['pass_size'] and not c['face_collage'] for c in m['head_checks'])
assert not (A/'parts/sword.png').exists() and not (A/'gear/leather_helmet/head.png').exists() and not (A/'gear/iron_helmet/head.png').exists()
(D/'asset_validation.json').write_text(json.dumps({'png_count':66,'parts':17,'base_and_new_gear_layers':28,'complete_heads':18,'inventory_icons':3,'outside_parent_plus24_total':outside,'ref_matches_source_frame0':True,'bare_normal_equals_cut_head':True,'joint_names_and_order_preserved':True,'files':records},indent=2)+'\n')
text='''# Số đo và các thay đổi theo phản hồi\n\nGiữ nguyên 8 vòng đầu. Sau phản hồi về đè layer và yêu cầu **đầu nguyên ảnh, chỉ căn kích thước**, các bản sửa được đo riêng, không ghi đè kết quả cũ.\n\n| Vòng đầu | IoU thân | IoU da | IoU sắt | Khớp lỗi /78 | Đạt toàn bộ |\n|---|---:|---:|---:|---:|---|\n'''
for r in history:
 text+=f"| {r['round']} | {r['body_iou_without_sword_4px']:.6f} | {r['outfits']['leather']['iou_without_sword_4px']:.6f} | {r['outfits']['iron']['iou_without_sword_4px']:.6f} | {sum(not c['pass'] for c in r['rotation'])} | {'Có' if r['all_pass'] else 'Chưa'} |\n"
text+='\n| Bản sửa sau phản hồi | IoU thân | IoU da | IoU sắt | Khớp lỗi /78 | Ghi chú |\n|---|---:|---:|---:|---:|---|\n'
notes={1:'Loại mặt/tai bị vẽ lại khỏi vật liệu nón',2:'Khóa vật liệu nón giữa biểu cảm',3:'Bỏ hẳn ghép mặt, dùng đầu nguyên ảnh',4:'Căn kích thước theo vùng đầu thật, bỏ ảnh hưởng của điểm alpha nhiễu'}
for r in corrections:
 text+=f"| {r['correction_after_user_feedback']} | {r['body_iou_without_sword_4px']:.6f} | {r['outfits']['leather']['iou_without_sword_4px']:.6f} | {r['outfits']['iron']['iou_without_sword_4px']:.6f} | {sum(not c['pass'] for c in r['rotation'])} | {notes[r['correction_after_user_feedback']]} |\n"
text+='''\n## Tiêu chí còn áp dụng\n\n- IoU thân ≥0.97, đồ ≥0.95; bỏ kiếm REF nới Euclidean 4px khỏi cả hai ảnh. IoU toàn REF + kiếm fixture chỉ tham khảo.\n- 28 lớp đồ nằm trong alpha mảnh chủ nới Euclidean 24px. Tất cả PNG game 512×512 RGBA và không chạm mép.\n- Khớp ±35°: trong bán kính 20px, không lỗ alpha kín và phải giữ tiếp xúc cha/con; nền tự nhiên ngoài người được ghi riêng. Các matrix theo đúng chuỗi cha/con, đồ đi theo mảnh chủ.\n- Bộ đầu hiện tại theo chỉ dẫn mới: một ảnh hoàn chỉnh cho mỗi kiểu/biểu cảm; chỉ crop khoảng trong suốt, resize và đặt nguyên ảnh. Không còn chèn mặt/tai/cằm REF. Vì vậy **không dùng các số cổ/cằm=0 của phương pháp ghép cũ để tuyên bố bộ đầu mới trùng pixel**. Đầu mới đo kích thước/vị trí và xoay cổ.\n- Kiểm tra pixel ngoài đồ vẫn giữ ngưỡng MAE≤10/255, P95≤30/255. Phần đầu mới được loại khỏi phép so mặt REF vì người dùng đã chuyển sang gen đầu hoàn chỉnh, chỉ căn kích thước.\n- Mask khăn cũ từng nhận nhầm nét viền nâu của áo thành màu đỏ, làm giữ lại nét áo xuyên qua giáp. Bản hiện tại chỉ bảo vệ màu khăn trong vùng khăn thực và owner cape.\n\nCác mask được sửa qua quá trình nên giá trị đăng ký không phải cùng một mask cố định. JSON từng vòng là số đo thực lúc chạy; `iteration_notes.md` và `corrections/baseline_after_8/` giữ lịch sử trước phản hồi.\n\n## Bản hiện tại\n\n'''
text+=f"- 18/18 đầu nguyên ảnh đạt kích thước/vị trí; {sum(c['pass'] for c in m['head_rotation'])}/36 ảnh xoay đầu ±20° liền cổ theo kiểm tra alpha.\n"
text+=f"- {sum(c['pass'] for c in m['rotation'])}/78 phép xoay bộ cơ bản đạt; 3 bộ giáp mới có {sum(c['pass'] for item in items for c in item['rotation_checks'])}/78 phép xoay không có lỗ alpha kín quanh khớp.\n"
for o,r in m['registration'].items():
 text+=f"- {o}: pixel vùng thân không mặc đồ — MAE {r['final_wear_protected_mae_rgb']:.3f}, P95 {r['final_wear_protected_p95_max_channel_error']:.0f}; {'đạt' if m['outfits'][o]['unclothed_pixels_nearly_identical'] else '**chưa đạt**'} ngưỡng giữ nguyên.\n"
text+='\nCác lần sửa sau ảnh phản hồi và 3 item bổ sung được ghi tách riêng, không đổi số của 8 vòng đầu, không nới ngưỡng. Chưa chứng nhận toàn bộ quy trình trùng pixel ngoài đồ.\n'
(D/'rounds.md').write_text(text)
item_rows='\n'.join(f"| `{i['id']}` | {i['name']} | 4 lớp rig + icon riêng |" for i in items)
handoff=f'''# Hero rig v2 — đầu nguyên ảnh và giáp bổ sung\n\nNhánh `art/hero-rig-v2` từ `core/world-life` tại `70abdb7`. Chỉ thay `assets/characters/hero_rig/` và `docs/ideas/`; không sửa code, scenes, tests, project hay icon có sẵn.\n\n## Theo phản hồi mới nhất\n\n**Không ghép mặt REF vào đầu có nón nữa.** Mỗi đầu là một ảnh liền nét: lấy kết quả image edit hoàn chỉnh, chỉ bỏ khoảng trong suốt rồi resize/đặt nguyên ảnh cho vừa vị trí đầu. Không cắt mắt/mũi/tai/cằm để dán lên ảnh khác. `bare_normal` vẫn là mảnh head cắt REF. 17 biến thể còn lại là 17 ảnh sửa nguyên đầu.\n\n- `heads/<bare|leather_helmet|iron_helmet>_<normal|blink|angry|hurt|happy|scared>.png`: đủ 18 ảnh, cùng canvas 512×512.\n- Khung đặt đầu thật được lấy từ vùng alpha chính của REF, không tính các điểm alpha nhiễu ở xa. Đầu không bị kéo ngang do nhiễu nền như bản sửa 3.\n- Không có `gear/leather_helmet/head.png` hay `gear/iron_helmet/head.png`; khi chọn đầu mới phải **thay head texture**, không vẽ thêm lên head cũ.\n- Nét áo cũ xuyên giáp được sửa bằng mask khăn đúng vùng, và đưa vạt áo/thắt lưng về owner pelvis. Giữ nguyên mảng `order` và tên 18 khớp.\n\n## Item giáp mới\n\n| ID | Tên | Asset |\n|---|---|---|\n{item_rows}\n\nMỗi bộ trong `gear/<id>/` có `torso`, `shield_arm_upper`, `sword_arm_upper`, `pelvis`. Icon ở `item_icons/<id>.png`, cũng 512×512 RGBA. **Rig được tách từ ảnh sửa nhân vật mặc giáp 3/4**, không lấy icon đứng riêng để ghép lên người. Các icon inventory được tạo sau cùng, chỉ dùng cho danh mục item.\n\n`new_items.json` kê đường dẫn và slot `armor`. Chưa đặt giá, chỉ số hay mốc mở khóa; chưa đăng ký vào danh mục game vì phạm vi nhánh chỉ ảnh/docs. Preview dùng chung đầu sắt normal và ủng leo núi.\n\n## Review\n\n- [heads_grid.png](heads_grid.png): 3 hàng kiểu đầu × 6 biểu cảm, tất cả là đầu nguyên ảnh.\n- [new_items_grid.png](new_items_grid.png): icon và dáng mặc của ba item mới.\n- [compare_bare.png](compare_bare.png), [compare_leather.png](compare_leather.png), [compare_iron.png](compare_iron.png): REF/WEAR cuối đặt cạnh bản lắp.\n- [head_layer_detail.png](head_layer_detail.png): phóng tai/gáy trước và sau, không còn hai mặt/tai chồng nhau.\n- [armor_layer_detail.png](armor_layer_detail.png): phóng giáp và vạt, không còn áo xanh che vạt giáp như ảnh phản hồi cũ.\n- [rotation_grid.png](rotation_grid.png), [new_items_rotation_grid.png](new_items_rotation_grid.png): bộ cơ bản và ba item mới xoay ±35° theo bone cha/con.\n- [heads_neck_rotation.png](heads_neck_rotation.png): 18 đầu ±20°.\n- [compare_ingame_sword.png](compare_ingame_sword.png): icon gốc, điểm (128,186) trùng grip, scale 210/256, không thêm phép xoay. Chỉ xem, không chấm điểm.\n\n## Số đo hiện tại và giới hạn\n\n- IoU thân bỏ kiếm+4px: **{m['body_iou_without_sword_4px']:.6f}**, ngưỡng ≥0.97.\n- IoU da: **{m['outfits']['leather']['iou_without_sword_4px']:.6f}**; sắt: **{m['outfits']['iron']['iou_without_sword_4px']:.6f}**, ngưỡng ≥0.95.\n- 66 PNG game: 17 mảnh thân, 28 lớp đồ, 18 đầu hoàn chỉnh, 3 icon item; tất cả RGBA 512×512. 0 pixel đồ ngoài owner+24px.\n- Các kiểm tra pixel vùng thân không mặc đồ **vẫn chưa đạt đầy đủ**; không dùng IoU hình bóng để khẳng định màu/viền trùng pixel. Xem [rounds.md](rounds.md) và JSON raw/cuối. Bộ đầu mới không ép pixel cổ/mặt bằng REF theo chỉ dẫn mới nhất của người dùng.\n- Asset item đã có; chưa xác nhận tích hợp gameplay hoặc chạy animation thực trong Godot. Giá/chỉ số và việc load đầu mới cần bên code tích hợp.\n\nKhông có kiếm mới trong assets. Kiếm cắt REF chỉ ở `fixtures/ref_sword.png`, sau nắm tay ở slot sword; mask kiếm được nới 4px khi chấm. `grip=[354,318]`, `neck=[262,237]`.\n\n## Tái tạo\n\n```sh\nOPENBLAS_NUM_THREADS=1 python3 docs/ideas/hero_rig_v2/build_v2.py --round 8 --correction 4\nOPENBLAS_NUM_THREADS=1 python3 docs/ideas/hero_rig_v2/build_new_items.py\npython3 docs/ideas/hero_rig_v2/write_report.py\n```\n\nCần Pillow, NumPy, SciPy, DejaVu Sans. Các script dùng input image edit đã lưu, không gọi network. Nguồn cũ và 8 vòng đầu được giữ để truy vết, không dùng số 0 cổ/cằm của cách ghép cũ để duyệt ảnh mới.\n\nBên code: thay đúng một head texture theo kiểu nón/biểu cảm; giữ nguyên offset neck, không thêm sprite đầu lên đầu cũ. Mỗi item armor gắn bốn lớp vào đúng bone; không cộng hai bộ armor cùng lúc. Map icon mới và đăng ký ba ID trong catalog theo cân bằng do người dùng/bên code quyết định.\n'''
(D/'handoff.md').write_text(handoff)
# Proof panels always read the current exports.
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)
proof=Image.new('RGB',(1000,310),'#eee7db');draw=ImageDraw.Draw(proof)
for i,(title,p) in enumerate([('REF',D/'bare_normal_source.png'),('Truoc sua',D/'corrections/baseline_after_8/iron_helmet_normal.png'),('Dau nguyen: sat',A/'heads/iron_helmet_normal.png'),('Dau nguyen: da',A/'heads/leather_helmet_normal.png')]):
 im=Image.open(p).convert('RGBA').crop((175,155,280,252)).resize((240,240),Image.Resampling.NEAREST);proof.paste(im,(i*250+5,50),im);draw.text((i*250+8,12),title,font=font,fill='#392a22')
proof.save(D/'head_layer_detail.png')
proof=Image.new('RGB',(1200,570),'#eee7db');draw=ImageDraw.Draw(proof)
for i,(title,p) in enumerate([('WEAR da',D/'wear_leather.png'),('Lap da',D/'assembled_leather.png'),('WEAR sat',D/'wear_iron.png'),('Lap sat',D/'assembled_iron.png')]):
 im=Image.open(p).convert('RGBA').crop((155,240,335,410)).resize((290,500),Image.Resampling.NEAREST);proof.paste(im,(i*300+5,50),im);draw.text((i*300+8,12),title,font=font,fill='#392a22')
proof.save(D/'armor_layer_detail.png')
print('66 assets audited; 18 coherent complete heads; 3 new armor items; scope unchanged. Protected-pixel status remains explicit in handoff.')
